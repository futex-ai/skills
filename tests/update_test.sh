#!/usr/bin/env bash
# Tests for scripts/update.sh: the fast-forward, the guards, the fetch limit,
# the log, the throttle, and the hook notices. The loop has its own file.
set -euo pipefail
# shellcheck source=tests/lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

update() { "$clone/scripts/update.sh" --state-dir "$state" "$@"; }

hook() {  # hook <event> <session id>: run the hook as Claude Code would
  printf '{"hook_event_name":"%s","session_id":"%s"}' "$1" "$2" | update --hook
}

test_reports_up_to_date() {
  make_fixture "$1"
  local out
  out="$(update)"
  assert_eq "up-to-date: $(short "$(head_of "$clone")")" "$out" "output"
  assert_contains "$(log_text)" " up-to-date: " "log"
  [[ -f "$state/skills-update.stamp" ]] || fail "stamp missing"
}

test_fast_forwards_and_links_a_new_skill() {
  make_fixture "$1"
  local old new out
  old="$(head_of "$clone")"
  write_skill gamma
  echo "more" >> "$work/skills/alpha/SKILL.md"
  commit_push "add gamma"
  new="$(head_of "$work")"
  out="$(update)"
  assert_eq "updated: $(short "$old") -> $(short "$new")" "$out" "output"
  assert_eq "$new" "$(head_of "$clone")" "clone HEAD"
  [[ -L "$HOME/.claude/skills/gamma" ]] || fail "gamma not linked for Claude Code"
  [[ -L "$HOME/.agents/skills/gamma" ]] || fail "gamma not linked for Codex"
  assert_contains "$(log_text)" "install: linked   $HOME/.claude/skills/gamma" "log"
}

test_removes_the_link_of_a_deleted_skill() {
  make_fixture "$1"
  git_t -C "$work" rm -q -r skills/beta
  commit_push "remove beta"
  update > /dev/null
  [[ ! -L "$HOME/.claude/skills/beta" ]] || fail "beta link still present"
  [[ ! -L "$HOME/.agents/skills/beta" ]] || fail "beta link still present for Codex"
  assert_contains "$(log_text)" "install: removed  $HOME/.claude/skills/beta (target is gone)" "log"
}

test_skips_a_clone_with_local_changes() {
  make_fixture "$1"
  local old out
  old="$(head_of "$clone")"
  echo "local edit" >> "$clone/skills/alpha/SKILL.md"
  write_skill gamma
  commit_push "add gamma"
  out="$(update)"
  assert_eq "skipped: local changes in $clone" "$out" "output"
  assert_eq "$old" "$(head_of "$clone")" "clone HEAD"
}

test_skips_a_clone_on_another_branch() {
  make_fixture "$1"
  git -C "$clone" checkout -q -b topic
  assert_eq "skipped: on branch 'topic', not main" "$(update)" "output"
}

test_skips_when_it_cannot_fast_forward() {
  make_fixture "$1"
  local old out
  echo "local commit" > "$clone/local.md"
  git_t -C "$clone" add local.md
  git_t -C "$clone" commit -q -m "local commit"
  old="$(head_of "$clone")"
  write_skill gamma
  commit_push "add gamma"
  out="$(update)"
  assert_eq "skipped: cannot fast-forward to $(short "$(head_of "$work")"): Not possible to fast-forward, aborting." \
    "$out" "output"
  assert_eq "$old" "$(head_of "$clone")" "clone HEAD"
}

test_skips_a_main_that_is_ahead_of_origin() {
  make_fixture "$1"
  local old out
  echo "local commit" > "$clone/local.md"
  git_t -C "$clone" add local.md
  git_t -C "$clone" commit -q -m "local commit"
  old="$(head_of "$clone")"
  out="$(update)"
  assert_eq "skipped: local main is ahead of origin/main ($(short "$(head_of "$work")"))" "$out" "output"
  assert_eq "$old" "$(head_of "$clone")" "clone HEAD"
  assert_lacks "$(log_text)" " updated: " "log"
  assert_eq "" "$(update --hook < /dev/null)" "hook output"
}

test_reports_a_failed_fetch_and_exits_zero() {
  make_fixture "$1"
  local out
  git -C "$clone" remote set-url origin "$1/missing.git"
  out="$(update)" || fail "exit status $?"
  assert_eq "failed: fetch from origin: '$1/missing.git' does not appear to be a git repository" "$out" "output"
  out="$(update --hook < /dev/null)" || fail "hook exit status $?"
  assert_eq "" "$out" "hook output"
}

test_stops_a_fetch_that_gives_no_answer() {
  make_fixture "$1"
  local out
  fake_git "$1/bin" 30
  out="$(PATH="$1/bin:$PATH" update --timeout 1)"
  assert_eq "failed: fetch from origin: no response within 1s" "$out" "output"
  assert_eq "up-to-date: $(short "$(head_of "$clone")")" "$(update)" "the real git works after it"
}

test_reports_a_stalled_fetch_as_no_response() {
  make_fixture "$1"
  local out
  fake_git "$1/bin" 30 "Warning: Permanently added 'github.com' (ED25519) to the list of known hosts."
  out="$(PATH="$1/bin:$PATH" update --timeout 1)"
  assert_eq "failed: fetch from origin: no response within 1s" "$out" "output"
}

test_skips_while_another_check_runs() {
  make_fixture "$1"
  local first out
  fake_git "$1/bin" 5
  PATH="$1/bin:$PATH" "$clone/scripts/update.sh" --state-dir "$state" --timeout 10 > /dev/null 2>&1 &
  first=$!
  wait_for 100 test -f "$state/skills-update.lock/pid" || fail "first check did not start"
  out="$(update)"
  end_process "$first"
  assert_eq "skipped: another update is running" "$out" "output"
}

test_keeps_the_log_small() {
  make_fixture "$1"
  local i
  for (( i = 0; i < 6000; i++ )); do echo "2026-01-01T00:00:00Z up-to-date: 0000000 line $i"; done \
    > "$state/skills-update.log"
  (( $(wc -c < "$state/skills-update.log") > 262144 )) || fail "seed log too small"
  update > /dev/null
  assert_eq "201" "$(wc -l < "$state/skills-update.log" | tr -d ' ')" "lines after truncation"
  assert_contains "$(tail -n 1 "$state/skills-update.log")" " up-to-date: $(short "$(head_of "$clone")")" "new line"
}

test_hook_is_silent_without_a_change() {
  make_fixture "$1"
  assert_eq "" "$(update --hook < /dev/null)" "hook output"
}

test_hook_prints_plain_text_for_a_prompt() {
  make_fixture "$1"
  local out
  echo "more" >> "$work/skills/alpha/SKILL.md"
  echo "new rule" >> "$work/global/AGENTS.md"
  commit_push "change alpha and the rules"
  out="$(printf '%s' '{"hook_event_name":"UserPromptSubmit"}' | update --hook)"
  assert_contains "$out" "Shared skills updated from " "context"
  assert_contains "$out" " Changed skills: alpha." "changed skills"
  assert_contains "$out" "read ~/.claude/CLAUDE.md again" "rules notice"
  assert_lacks "$out" "hookSpecificOutput" "no JSON for a prompt"
}

test_hook_prints_json_for_session_start() {
  make_fixture "$1"
  local out context
  write_skill gamma
  commit_push "add gamma"
  out="$(printf '%s' '{"hook_event_name":"SessionStart","source":"startup"}' | update --hook)"
  assert_eq "SessionStart" "$(jq -r .hookSpecificOutput.hookEventName <<< "$out")" "event"
  assert_eq "true" "$(jq -r .hookSpecificOutput.reloadSkills <<< "$out")" "reloadSkills"
  context="$(jq -r .hookSpecificOutput.additionalContext <<< "$out")"
  assert_contains "$context" " Changed skills: gamma." "changed skills"
  assert_lacks "$context" "always-on rules" "rules unchanged"
}

test_hook_tells_a_session_about_an_update_by_another_process() {
  make_fixture "$1"
  local out
  assert_eq "" "$(hook UserPromptSubmit s1)" "first prompt"
  assert_eq "$(head_of "$clone")" "$(cat "$state/sessions/s1")" "session file"
  write_skill gamma
  commit_push "add gamma"
  update > /dev/null
  out="$(hook UserPromptSubmit s1)"
  assert_contains "$out" " Changed skills: gamma." "notice after the loop updated"
  assert_eq "" "$(hook UserPromptSubmit s1)" "told once"
  assert_eq "" "$(hook SessionStart s1)" "resume with nothing new"
  assert_eq "" "$(hook SessionStart s9)" "a new session starts current"
}

test_hook_announces_an_opt_in_skill_only_where_it_is_linked() {
  make_fixture "$1"
  local out
  hook SessionStart s1 > /dev/null
  write_skill gamma
  echo "for the skills repository only" > "$work/skills/gamma/opt-in"
  echo "more" >> "$work/skills/alpha/SKILL.md"
  commit_push "add the opt-in skill gamma"
  out="$(hook UserPromptSubmit s1)"
  assert_contains "$out" " Changed skills: alpha." "the linked skill is announced"
  assert_lacks "$out" "gamma" "the opt-in skill is not announced"
  [[ ! -e "$HOME/.claude/skills/gamma" ]] || fail "the update linked the opt-in skill"
  "$clone/scripts/install.sh" --opt-in --quiet > /dev/null
  echo "more" >> "$work/skills/gamma/SKILL.md"
  commit_push "change gamma"
  assert_contains "$(hook UserPromptSubmit s1)" " Changed skills: gamma." "announced once linked"
}

test_hook_tells_each_session_once() {
  make_fixture "$1"
  hook SessionStart s1 > /dev/null
  hook SessionStart s2 > /dev/null
  write_skill gamma
  commit_push "add gamma"
  assert_contains "$(hook UserPromptSubmit s1)" "gamma" "session 1 applied the update"
  assert_contains "$(hook UserPromptSubmit s2)" "gamma" "session 2 hears about it"
  assert_eq "" "$(hook UserPromptSubmit s1)" "session 1 told once"
  assert_eq "" "$(hook UserPromptSubmit s2)" "session 2 told once"
}

test_hook_announces_a_resume_with_json() {
  make_fixture "$1"
  local out
  hook SessionStart s1 > /dev/null
  write_skill gamma
  commit_push "add gamma"
  update > /dev/null
  out="$(hook SessionStart s1)"
  assert_eq "true" "$(jq -r .hookSpecificOutput.reloadSkills <<< "$out")" "reloadSkills"
  assert_contains "$(jq -r .hookSpecificOutput.additionalContext <<< "$out")" " Changed skills: gamma." "context"
}

test_hook_forgets_idle_sessions_only() {
  make_fixture "$1"
  mkdir -p "$state/sessions"
  touch -t 202001010000 "$state/sessions/old"
  head_of "$clone" > "$state/sessions/active"
  touch -t 202001010000 "$state/sessions/active"
  assert_eq "" "$(hook UserPromptSubmit active)" "the active session has nothing new"
  hook UserPromptSubmit s1 > /dev/null
  [[ ! -f "$state/sessions/old" ]] || fail "old session file kept"
  [[ -f "$state/sessions/active" ]] || fail "the file of the active session was removed"
  [[ -f "$state/sessions/s1" ]] || fail "new session file missing"
}

test_min_interval_skips_a_recent_check() {
  make_fixture "$1"
  local old out
  old="$(head_of "$clone")"
  write_skill gamma
  commit_push "add gamma"
  echo 1000 > "$state/skills-update.stamp"
  out="$(SKILLS_UPDATE_NOW=1100 update --min-interval 300)"
  assert_eq "skipped: last check 100s ago" "$out" "throttled output"
  assert_eq "$old" "$(head_of "$clone")" "clone HEAD"
  assert_eq "" "$(SKILLS_UPDATE_NOW=1100 update --hook --min-interval 300 < /dev/null)" "hook"
  out="$(SKILLS_UPDATE_NOW=1400 update --min-interval 300)"
  assert_contains "$out" "updated: $(short "$old") -> " "after the interval"
  assert_eq "1400" "$(cat "$state/skills-update.stamp")" "stamp"
}

test_rejects_a_bad_option_value() {
  make_fixture "$1"
  local status=0
  update --loop abc > /dev/null 2>&1 || status=$?
  assert_eq "2" "$status" "exit status"
  status=0
  update --detach > /dev/null 2>&1 || status=$?
  assert_eq "2" "$status" "detach without loop"
}

run_all_tests

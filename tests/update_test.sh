#!/usr/bin/env bash
# Tests for scripts/update.sh: the fast-forward, the guards, the hook output,
# the throttle, the loop, and the detached start.
set -euo pipefail
# shellcheck source=tests/lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

update() { "$clone/scripts/update.sh" --state-dir "$state" "$@"; }

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
  assert_contains "$out" "skipped: cannot fast-forward to $(short "$(head_of "$work")")" "output"
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
  assert_contains "$out" "failed: fetch from origin: " "output"
  out="$(update --hook < /dev/null)" || fail "hook exit status $?"
  assert_eq "" "$out" "hook output"
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

test_loop_runs_max_runs_times_then_stops() {
  make_fixture "$1"
  update --loop 0 --max-runs 3
  assert_eq "3" "$(grep -c ' up-to-date: ' "$state/skills-update.log")" "checks"
  assert_contains "$(log_text)" "loop: stopped after 3 checks" "log"
  [[ ! -d "$state/skills-loop.lock" ]] || fail "loop lock not released"
}

test_loop_refuses_a_second_loop() {
  make_fixture "$1"
  local first out
  "$clone/scripts/update.sh" --state-dir "$state" --loop 60 --max-runs 2 > /dev/null 2>&1 &
  first=$!
  wait_for 100 test -f "$state/skills-loop.lock/pid" || fail "first loop did not start"
  out="$(update --loop 0 --max-runs 1)"
  kill "$first" 2>/dev/null || true
  assert_eq "skipped: another update loop is running (pid $first)" "$out" "output"
}

test_loop_takes_over_a_stale_lock() {
  make_fixture "$1"
  mkdir -p "$state/skills-loop.lock"
  sh -c 'echo $$' > "$state/skills-loop.lock/pid"
  update --loop 0 --max-runs 1
  assert_contains "$(log_text)" " up-to-date: " "log"
  [[ ! -d "$state/skills-loop.lock" ]] || fail "loop lock not released"
}

test_loop_ignores_a_pid_that_is_not_an_update_loop() {
  make_fixture "$1"
  local other
  sleep 30 > /dev/null 2>&1 &
  other=$!
  mkdir -p "$state/skills-loop.lock"
  echo "$other" > "$state/skills-loop.lock/pid"
  update --loop 0 --max-runs 1
  kill "$other"
  assert_contains "$(log_text)" " up-to-date: " "log"
}

test_loop_trusts_a_live_pid_when_ps_fails() {
  make_fixture "$1"
  local other out
  mkdir -p "$1/bin"
  printf '#!/usr/bin/env bash\nexit 1\n' > "$1/bin/ps"
  chmod +x "$1/bin/ps"
  sleep 30 > /dev/null 2>&1 &
  other=$!
  mkdir -p "$state/skills-loop.lock"
  echo "$other" > "$state/skills-loop.lock/pid"
  out="$(PATH="$1/bin:$PATH" update --loop 0 --max-runs 1)"
  kill "$other"
  assert_eq "skipped: another update loop is running (pid $other)" "$out" "output"
}

test_loop_restarts_with_the_new_script() {
  make_fixture "$1"
  sed 's/loop: stopped after/loop v2: stopped after/' "$work/scripts/update.sh" > "$work/update.new"
  mv "$work/update.new" "$work/scripts/update.sh"
  chmod +x "$work/scripts/update.sh"
  commit_push "change update.sh"
  update --loop 0 --max-runs 2
  assert_contains "$(log_text)" " updated: " "first check"
  assert_contains "$(log_text)" "loop: update.sh changed, restarting" "restart"
  assert_contains "$(log_text)" "loop v2: stopped after 1 checks" "second check by the new script"
}

test_detach_starts_the_loop_in_the_background() {
  make_fixture "$1"
  local out
  out="$(update --detach --loop 0 --max-runs 1)"
  assert_eq "started: update loop every 0s, log in $state/skills-update.log" "$out" "output"
  wait_for 100 grep -q "loop: stopped" "$state/skills-update.log" || fail "loop did not finish"
  assert_contains "$(log_text)" " up-to-date: " "log"
}

test_detach_skips_when_a_loop_is_running() {
  make_fixture "$1"
  local first out
  "$clone/scripts/update.sh" --state-dir "$state" --loop 60 --max-runs 2 > /dev/null 2>&1 &
  first=$!
  wait_for 100 test -f "$state/skills-loop.lock/pid" || fail "first loop did not start"
  out="$(update --detach --loop 0)"
  kill "$first" 2>/dev/null || true
  assert_eq "skipped: update loop already running (pid $first), log in $state/skills-update.log" "$out" "output"
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

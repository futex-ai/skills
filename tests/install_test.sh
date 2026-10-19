#!/usr/bin/env bash
# Tests for scripts/install.sh: quiet mode, dangling-link removal, the Codex
# home directory, opt-in skills, the Claude Code hooks, and uninstall.
set -euo pipefail
# shellcheck source=tests/lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

install() { "$clone/scripts/install.sh" "$@"; }

settings_file() { printf '%s' "$HOME/.claude/settings.json"; }

test_quiet_prints_only_changes() {
  make_fixture "$1"
  assert_eq "" "$(install --quiet)" "second quiet run"
  assert_contains "$(install)" "linked   $HOME/.claude/skills/alpha" "verbose run"
}

test_removes_dangling_links_into_the_repository_only() {
  make_fixture "$1"
  local out
  ln -s "$clone/skills/zeta" "$HOME/.claude/skills/zeta"
  ln -s "$1/elsewhere" "$HOME/.claude/skills/other"
  out="$(install --quiet)"
  assert_eq "removed  $HOME/.claude/skills/zeta (target is gone)" "$out" "output"
  [[ ! -L "$HOME/.claude/skills/zeta" ]] || fail "zeta link still present"
  [[ -L "$HOME/.claude/skills/other" ]] || fail "foreign link removed"
  [[ -L "$HOME/.claude/skills/alpha" ]] || fail "valid link removed"
}

test_removes_a_dangling_rules_link() {
  make_fixture "$1"
  rm "$clone/global/AGENTS.md"
  assert_contains "$(install --quiet)" "removed  $HOME/.claude/CLAUDE.md (target is gone)" "output"
  [[ ! -L "$HOME/.claude/CLAUDE.md" ]] || fail "rules link still present"
}

test_codex_home_stays_a_skill_root() {
  make_fixture "$1"
  install --codex-home --quiet > /dev/null
  [[ -L "$HOME/.codex/skills/alpha" ]] || fail "alpha not linked into the Codex home"
  mkdir -p "$clone/skills/gamma"
  printf -- '---\nname: gamma\ndescription: test\n---\n' > "$clone/skills/gamma/SKILL.md"
  install --quiet > /dev/null
  [[ -L "$HOME/.codex/skills/gamma" ]] || fail "gamma not linked into the Codex home"
}

test_opt_in_skill_is_linked_only_on_request() {
  make_fixture "$1"
  mkdir -p "$clone/skills/gamma"
  printf -- '---\nname: gamma\ndescription: test\n---\n' > "$clone/skills/gamma/SKILL.md"
  echo "for the skills repository only" > "$clone/skills/gamma/opt-in"
  assert_contains "$(install)" "skipped  gamma (opt-in skill; pass --opt-in to link it)" "verbose skip"
  assert_eq "" "$(install --quiet)" "quiet run says nothing"
  [[ ! -e "$HOME/.claude/skills/gamma" ]] || fail "gamma linked without the flag"
  [[ ! -e "$HOME/.agents/skills/gamma" ]] || fail "gamma linked into .agents without the flag"
  [[ -L "$HOME/.claude/skills/alpha" ]] || fail "alpha not linked"
  assert_contains "$(install --opt-in --quiet)" "linked   $HOME/.claude/skills/gamma" "flag links it"
  [[ -L "$HOME/.agents/skills/gamma" ]] || fail "gamma not linked into .agents with the flag"
  assert_eq "" "$(install --quiet)" "later run keeps the link quietly"
  [[ -L "$HOME/.claude/skills/gamma" ]] || fail "later run removed the link"
  install --uninstall > /dev/null
  [[ ! -L "$HOME/.claude/skills/gamma" ]] || fail "uninstall left the link"
}

test_hooks_are_added_once() {
  make_fixture "$1"
  local s
  s="$(settings_file)"
  assert_contains "$(install --hooks --quiet)" "hooks    added to $s" "output"
  assert_eq "" "$(install --hooks --quiet)" "second quiet run"
  assert_eq "hooks    unchanged in $s" "$(install --hooks | grep hooks)" "second verbose run"
  assert_eq "1" "$(jq '.hooks.SessionStart | length' "$s")" "SessionStart entries"
  assert_eq "1" "$(jq '.hooks.UserPromptSubmit | length' "$s")" "UserPromptSubmit entries"
  assert_eq "\"$clone/scripts/update.sh\" --hook --min-interval 60" \
    "$(jq -r '.hooks.SessionStart[0].hooks[0].command' "$s")" "SessionStart command"
  assert_eq "60" "$(jq '.hooks.SessionStart[0].hooks[0].timeout' "$s")" "SessionStart timeout"
  assert_eq "\"$clone/scripts/update.sh\" --hook --min-interval 300" \
    "$(jq -r '.hooks.UserPromptSubmit[0].hooks[0].command' "$s")" "UserPromptSubmit command"
  assert_eq "true" "$(jq '.hooks.UserPromptSubmit[0].hooks[0].async' "$s")" "UserPromptSubmit async"
  [[ -n "$(find "$s" -perm 0600)" ]] || fail "settings file mode is not 0600"
}

test_hooks_keep_other_settings() {
  make_fixture "$1"
  local s
  s="$(settings_file)"
  mkdir -p "$HOME/.claude"
  cat > "$s" <<'JSON'
{"env": {"X": "1"}, "hooks": {"SessionStart": [{"hooks": [{"type": "command", "command": "echo hi"}]}]}}
JSON
  install --hooks --quiet > /dev/null
  assert_eq "1" "$(jq -r .env.X "$s")" "env kept"
  assert_eq "2" "$(jq '.hooks.SessionStart | length' "$s")" "foreign hook kept"
  assert_eq "echo hi" "$(jq -r '.hooks.SessionStart[0].hooks[0].command' "$s")" "foreign hook first"
}

test_hooks_skip_invalid_json() {
  make_fixture "$1"
  local s
  s="$(settings_file)"
  mkdir -p "$HOME/.claude"
  echo '{not json' > "$s"
  assert_eq "skipped  hooks ($s is not valid JSON)" "$(install --hooks --quiet)" "output"
  assert_eq '{not json' "$(cat "$s")" "file unchanged"
}

test_hooks_skip_a_file_that_is_not_an_object() {
  make_fixture "$1"
  local s
  s="$(settings_file)"
  mkdir -p "$HOME/.claude"
  printf '  \n' > "$s"
  assert_eq "skipped  hooks ($s is not a JSON object)" "$(install --hooks --quiet)" "whitespace output"
  assert_eq "3" "$(wc -c < "$s" | tr -d ' ')" "whitespace file unchanged"
  echo '[]' > "$s"
  assert_eq "skipped  hooks ($s is not a JSON object)" "$(install --hooks --quiet)" "array output"
  assert_eq '[]' "$(cat "$s")" "array file unchanged"
  [[ -z "$(find "$HOME/.claude" -name 'settings.json.*')" ]] || fail "temp file left behind"
}

test_hooks_write_through_a_symlink() {
  make_fixture "$1"
  local s target="$1/dotfiles/settings.json"
  s="$(settings_file)"
  mkdir -p "$HOME/.claude" "$1/dotfiles"
  echo '{"env": {"X": "1"}}' > "$target"
  ln -s "$target" "$s"
  install --hooks --quiet > /dev/null
  [[ -L "$s" ]] || fail "settings path is no longer a symlink"
  assert_eq "1" "$(jq '.hooks.SessionStart | length' "$target")" "hooks in the target"
  assert_eq "1" "$(jq -r .env.X "$target")" "env kept"
  install --uninstall > /dev/null
  [[ -L "$s" ]] || fail "settings path is no longer a symlink after uninstall"
  assert_eq "null" "$(jq -c .hooks "$target")" "hooks removed from the target"
}

test_uninstall_removes_links_and_hooks() {
  make_fixture "$1"
  local s
  s="$(settings_file)"
  install --hooks --quiet > /dev/null
  ln -s "$clone/skills/zeta" "$HOME/.claude/skills/zeta"
  install --uninstall > /dev/null
  [[ ! -L "$HOME/.claude/skills/alpha" ]] || fail "alpha link still present"
  [[ ! -L "$HOME/.claude/skills/zeta" ]] || fail "dangling link still present"
  [[ ! -L "$HOME/.claude/CLAUDE.md" ]] || fail "rules link still present"
  assert_eq "null" "$(jq -c .hooks "$s")" "hooks removed"
}

test_uninstall_stops_the_loop() {
  make_fixture "$1"
  local pid out
  "$clone/scripts/update.sh" --detach --loop 60 > /dev/null
  wait_for 100 test -s "$HOME/.futex/skills-loop.lock/pid" || fail "loop did not start"
  pid="$(cat "$HOME/.futex/skills-loop.lock/pid")"
  out="$(install --uninstall)"
  assert_contains "$out" "stopped: update loop (pid $pid)" "output"
  [[ ! -d "$HOME/.futex/skills-loop.lock" ]] || fail "loop lock still present"
  wait_for 100 bash -c "! kill -0 $pid 2>/dev/null" || fail "loop still running"
}

test_uninstall_leaves_a_settings_file_without_our_hooks_alone() {
  make_fixture "$1"
  local s before out
  s="$(settings_file)"
  mkdir -p "$HOME/.claude"
  printf '{ "env": {"X": "1"},\n  "hooks": {"Stop": [{"hooks": [{"type": "command", "command": "echo bye"}]}]} }\n' > "$s"
  before="$(cat "$s")"
  out="$(install --uninstall)"
  assert_eq "$before" "$(cat "$s")" "file bytes"
  assert_contains "$out" "hooks    unchanged in $s" "output"
  assert_lacks "$out" "hooks    removed" "no removal claim"
}

run_all_tests

#!/usr/bin/env bash
# Tests for scripts/install.sh: quiet mode, dangling-link removal, the Claude
# Code hooks, and uninstall.
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

test_hooks_are_added_once() {
  make_fixture "$1"
  local s
  s="$(settings_file)"
  assert_contains "$(install --hooks --quiet)" "hooks    added to $s" "output"
  install --hooks --quiet > /dev/null
  assert_eq "1" "$(jq '.hooks.SessionStart | length' "$s")" "SessionStart entries"
  assert_eq "1" "$(jq '.hooks.UserPromptSubmit | length' "$s")" "UserPromptSubmit entries"
  assert_eq "\"$clone/scripts/update.sh\" --hook" \
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
  assert_eq "{}" "$(jq -c .hooks "$s")" "hooks removed"
}

run_all_tests

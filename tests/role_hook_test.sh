#!/usr/bin/env bash
# Tests for the role marker, the role reminders, and idle marker cleanup.
set -euo pipefail
# shellcheck source=tests/lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
export LC_ALL=C TZ=UTC

role_marker() {  # role_marker <session id>: the marker path in the test HOME
  printf '%s' "$HOME/.futex/roles/$1"
}

role() {  # role <command>: run the marker script under test
  "$repo_under_test/skills/coordinator/scripts/role.sh" "$@"
}

hook() {  # hook <event> <session id>: run the hook as Claude Code would
  printf '{"session_id":"%s","hook_event_name":"%s"}' "$2" "$1" \
    | "$repo_under_test/scripts/role-hook.sh"
}

test_hook_without_a_marker_is_silent_and_creates_nothing() {
  export HOME="$1/home" CLAUDE_CODE_SESSION_ID=s1
  local out
  out="$(hook UserPromptSubmit s1)" || fail "hook exit status $?"
  assert_eq "" "$out" "unmarked session"
  [[ ! -d "$(dirname "$(role_marker s1)")" ]] || fail "hook created the roles directory"
}

test_hook_ignores_another_sessions_marker() {
  export HOME="$1/home" CLAUDE_CODE_SESSION_ID=other
  local out
  role start > /dev/null || fail "start exit status $?"
  out="$(hook UserPromptSubmit s1)" || fail "hook exit status $?"
  assert_eq "" "$out" "another session's marker"
}

test_prompt_prints_the_started_roles_exact_reminder() {
  export HOME="$1/home" CLAUDE_CODE_SESSION_ID=s1
  local out
  role start > /dev/null || fail "start exit status $?"
  out="$(printf '{"session_id":"s1","transcript_path":"/tmp/transcript.jsonl","cwd":"/tmp/project","hook_event_name":"UserPromptSubmit","prompt":"Continue"}' \
    | "$repo_under_test/scripts/role-hook.sh")" || fail "hook exit status $?"
  assert_eq "Role reminder: this session holds the coordinator role. Follow the \`coordinator\` skill. When its full text is not in your context, read $HOME/.claude/skills/coordinator/SKILL.md first." \
    "$out" "prompt reminder"
}

test_session_start_prints_the_started_roles_read_now_reminder() {
  export HOME="$1/home" CLAUDE_CODE_SESSION_ID=s1
  local out
  role start > /dev/null || fail "start exit status $?"
  out="$(hook SessionStart s1)" || fail "hook exit status $?"
  assert_eq "Role reminder: this session holds the coordinator role. Read $HOME/.claude/skills/coordinator/SKILL.md now, before you act, and follow the \`coordinator\` skill." \
    "$out" "session start reminder"
}

test_other_and_missing_events_stay_silent() {
  export HOME="$1/home" CLAUDE_CODE_SESSION_ID=s1
  local out
  role start > /dev/null || fail "start exit status $?"
  out="$(hook Stop s1)" || fail "Stop exit status $?"
  assert_eq "" "$out" "Stop output"
  out="$(printf '{"session_id":"s1"}' | "$repo_under_test/scripts/role-hook.sh")" || fail "missing event exit status $?"
  assert_eq "" "$out" "missing event output"
}

test_bad_ids_and_marker_names_stay_silent() {
  export HOME="$1/home" CLAUDE_CODE_SESSION_ID=s1
  local out
  role start > /dev/null || fail "start exit status $?"
  [[ -f "$(role_marker ../roles/s1)" ]] || fail "bad id does not reach the real marker"
  out="$(hook UserPromptSubmit ../roles/s1)" || fail "bad id exit status $?"
  assert_eq "" "$out" "bad session id"
  printf '../coordinator\n' > "$(role_marker s1)" || fail "write bad marker"
  out="$(hook UserPromptSubmit s1)" || fail "bad marker exit status $?"
  assert_eq "" "$out" "bad skill name"
}

test_empty_and_broken_input_stay_silent() {
  export HOME="$1/home" CLAUDE_CODE_SESSION_ID=s1
  local out input
  role start > /dev/null || fail "start exit status $?"
  out="$("$repo_under_test/scripts/role-hook.sh" < /dev/null)" || fail "no input exit status $?"
  assert_eq "" "$out" "no input output"
  for input in '' '{not json'; do
    out="$(printf '%s' "$input" | "$repo_under_test/scripts/role-hook.sh")" || fail "input '$input' exit status $?"
    assert_eq "" "$out" "input '$input' output"
  done
}

test_start_marks_the_session_and_reports_hook_installation() {
  export HOME="$1/home" CLAUDE_CODE_SESSION_ID=s1
  local out marker
  marker="$(role_marker s1)"
  mkdir -p "$HOME/.claude"
  cat > "$HOME/.claude/settings.json" <<JSON
{"hooks": {"SessionStart": [{"hooks": [{"type": "command", "command": "\"$repo_under_test/scripts/update.sh\" --hook --min-interval 60", "timeout": 60}]}]}}
JSON
  out="$(role start)" || fail "start with the update hook only exit status $?"
  assert_eq "role: marked this session for the coordinator role in $marker
role: the role hook is not installed in $HOME/.claude/settings.json; run scripts/install.sh --hooks in the skills clone, or type /coordinator again after a compaction" \
    "$out" "start with the update hook only"
  "$repo_under_test/scripts/install.sh" --hooks --quiet > /dev/null || fail "install hooks exit status $?"
  out="$(role start)" || fail "start with hooks exit status $?"
  assert_eq "role: marked this session for the coordinator role in $marker
role: the role hook is installed in $HOME/.claude/settings.json" "$out" "start with hooks"
}

test_stop_removes_the_marker_and_stops_reminders() {
  export HOME="$1/home" CLAUDE_CODE_SESSION_ID=s1
  local out
  role start > /dev/null || fail "start exit status $?"
  out="$(role stop)" || fail "stop exit status $?"
  assert_eq "role: removed the role marker $(role_marker s1)" "$out" "stop output"
  [[ ! -e "$(role_marker s1)" ]] || fail "stop left the marker"
  out="$(hook UserPromptSubmit s1)" || fail "hook after stop exit status $?"
  assert_eq "" "$out" "hook after stop"
  out="$(role stop)" || fail "second stop exit status $?"
  assert_eq 'role: this session has no role marker' "$out" "second stop output"
}

test_missing_empty_and_bad_ids_create_no_role_directory() {
  export HOME="$1/home"
  unset CLAUDE_CODE_SESSION_ID
  local out command id
  for command in start stop; do
    out="$(env -u CLAUDE_CODE_SESSION_ID "$repo_under_test/skills/coordinator/scripts/role.sh" "$command")" \
      || fail "$command without id exit status $?"
    assert_eq 'role: the role hook needs Claude Code; CLAUDE_CODE_SESSION_ID is missing or not valid' "$out" "$command without id"
    for id in '' '../roles/s1'; do
      out="$(CLAUDE_CODE_SESSION_ID="$id" role "$command")" || fail "$command with id '$id' exit status $?"
      assert_eq 'role: the role hook needs Claude Code; CLAUDE_CODE_SESSION_ID is missing or not valid' "$out" "$command with id '$id'"
    done
  done
  [[ ! -d "$(dirname "$(role_marker s1)")" ]] || fail "invalid id created the roles directory"
}

test_cleanup_removes_idle_markers_after_refreshing_the_current_marker() {
  export HOME="$1/home" CLAUDE_CODE_SESSION_ID=current
  local out stale
  role start > /dev/null || fail "start current exit status $?"
  CLAUDE_CODE_SESSION_ID=old role start > /dev/null || fail "start old exit status $?"
  CLAUDE_CODE_SESSION_ID=fresh role start > /dev/null || fail "start fresh exit status $?"
  touch -d 2020-01-01T00:00:00 "$(role_marker old)" "$(role_marker current)" || fail "age markers"
  out="$(hook UserPromptSubmit current)" || fail "cleanup exit status $?"
  assert_eq "Role reminder: this session holds the coordinator role. Follow the \`coordinator\` skill. When its full text is not in your context, read $HOME/.claude/skills/coordinator/SKILL.md first." \
    "$out" "reminder after cleanup"
  [[ ! -e "$(role_marker old)" ]] || fail "idle marker kept"
  [[ -f "$(role_marker fresh)" ]] || fail "fresh marker removed"
  [[ -f "$(role_marker current)" ]] || fail "current marker removed before refresh"
  stale="$(find "$(role_marker current)" -mtime +30 -print)" || fail "inspect marker age exit status $?"
  assert_eq "" "$stale" "current marker is fresh"
  touch -d 2020-01-01T00:00:00 "$(role_marker fresh)" || fail "age remaining marker"
  out="$(hook Stop unmarked)" || fail "unmarked cleanup exit status $?"
  assert_eq "" "$out" "unmarked cleanup output"
  [[ ! -e "$(role_marker fresh)" ]] || fail "unmarked session left an idle marker"
}

test_usage_errors_print_usage_and_exit_two() {
  export HOME="$1/home" CLAUDE_CODE_SESSION_ID=s1
  local arg status out errors errors_file="$1/errors"
  for arg in '' unknown start stop; do
    case "$arg" in
      '') set -- ;;
      start|stop) set -- "$arg" extra ;;
      *) set -- "$arg" ;;
    esac
    status=0
    out="$(role "$@" 2> "$errors_file")" || status=$?
    errors="$(cat "$errors_file")" || fail "read usage error exit status $?"
    assert_eq "2" "$status" "usage exit status for '$arg'"
    assert_eq "" "$out" "usage stdout for '$arg'"
    assert_eq 'usage: role.sh start|stop' "$errors" "usage stderr for '$arg'"
  done
}

test_failed_refresh_and_cleanup_keep_the_reminder() {
  export HOME="$1/home" CLAUDE_CODE_SESSION_ID=s1
  local out command
  role start > /dev/null || fail "start exit status $?"
  mkdir -p "$1/bin" || fail "create command directory"
  for command in touch find; do
    printf '#!/usr/bin/env bash\necho "%s failed" >&2\nexit 1\n' "$command" > "$1/bin/$command" || fail "write failing $command"
    chmod +x "$1/bin/$command" || fail "make failing $command executable"
  done
  out="$(PATH="$1/bin:$PATH" hook UserPromptSubmit s1 2> "$1/errors")" || fail "failed maintenance exit status $?"
  assert_eq "Role reminder: this session holds the coordinator role. Follow the \`coordinator\` skill. When its full text is not in your context, read $HOME/.claude/skills/coordinator/SKILL.md first." \
    "$out" "reminder after failed maintenance"
}

run_all_tests

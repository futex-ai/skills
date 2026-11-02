#!/usr/bin/env bash
# Tests for the scripts of the coordinator skill, against a fake conductor
# CLI that answers from files.
set -euo pipefail
# shellcheck source=tests/lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

scripts="$repo_under_test/skills/coordinator/scripts"

fake_conductor() {  # fake_conductor <dir>: a conductor that answers from <dir>/answers/<args>.json
  mkdir -p "$1/bin" "$1/answers"
  cat > "$1/bin/conductor" <<'FAKE'
#!/usr/bin/env bash
# Answer each call from a file named after its arguments, without --json.
key=""
for a in "$@"; do
  [[ "$a" == --json ]] && continue
  key="${key:+${key}_}$a"
done
file="$FAKE_ANSWERS/$key.json"
if [[ ! -f "$file" ]]; then echo "fake conductor: no answer for '$key'" >&2; exit 1; fi
cat "$file"
FAKE
  chmod +x "$1/bin/conductor"
  export FAKE_ANSWERS="$1/answers"
  PATH="$1/bin:$PATH"
}

answer() {  # answer <key> <json>: the fake's answer for the call with that key
  printf '%s\n' "$2" > "$FAKE_ANSWERS/$1.json"
}

page() {  # page <key> <hasMore> <items json>: one page of a list answer
  answer "$1" "{\"data\":$3,\"offset\":0,\"hasMore\":$2}"
}

test_last_report_gives_a_later_claude_error_across_pages() {
  fake_conductor "$1"
  answer "session_status_s1" '{"status":"idle"}'
  page "session_message_s1_--limit_100_--offset_0" true '[{"type":"userMessage","content":{"message":"go"}},{"type":"agent","content":{"rawPayload":{"type":"assistant","message":{"content":[{"type":"text","text":"thinking aloud"}]}}}},{"type":"agent","content":{"rawPayload":{"type":"result","subtype":"success","is_error":false,"result":"first report"}}}]'
  page "session_message_s1_--limit_100_--offset_3" false '[{"type":"userMessage","content":{"message":"continue"}},{"type":"agent","content":{"rawPayload":{"type":"result","subtype":"success","is_error":true,"result":"API Error: 429"}}}]'
  assert_eq "error: API Error: 429" "$("$scripts/last-report.sh" s1)" "claude error"
  answer "session_status_s8" '{"status":"idle"}'
  page "session_message_s8_--limit_100_--offset_0" false '[{"type":"userMessage","content":{"id":"m-1","message":"go"}},{"type":"agent","content":{"rawPayload":{"type":"result","subtype":"error_during_execution","is_error":true,"errors":["first failure","second failure"]}}}]'
  assert_eq "error: error_during_execution: first failure: second failure" "$("$scripts/last-report.sh" s8)" "claude error list"
}

test_last_report_gives_the_codex_error_that_ended_the_turn() {
  fake_conductor "$1"
  answer "session_status_s5" '{"status":"idle"}'
  page "session_message_s5_--limit_100_--offset_0" false '[{"type":"agent","content":{"rawPayload":{"event":{"type":"item.completed","item":{"type":"agentMessage","text":"saving the report"}}}}},{"type":"agent","content":{"rawPayload":{"event":{"type":"error","message":"Reconnecting... 1/5","willRetry":true,"additionalDetails":"last status: 429 Too Many Requests"}}}}]'
  assert_eq "error: Reconnecting... 1/5: last status: 429 Too Many Requests" "$("$scripts/last-report.sh" s5)" "codex error"
}

test_last_report_gives_the_codex_message_after_a_recovered_error() {
  fake_conductor "$1"
  answer "session_status_s6" '{"status":"idle"}'
  page "session_message_s6_--limit_100_--offset_0" false '[{"type":"agent","content":{"rawPayload":{"event":{"type":"error","message":"Reconnecting... 1/5","willRetry":true}}}},{"type":"agent","content":{"rawPayload":{"event":{"type":"item.completed","item":{"type":"agentMessage","text":"final report"}}}}},{"type":"agent","content":{"rawPayload":{"event":{"type":"turn.completed"}}}}]'
  assert_eq "final report" "$("$scripts/last-report.sh" s6)" "recovered codex turn"
}

test_last_report_reads_a_codex_session() {
  fake_conductor "$1"
  answer "session_status_s2" '{"status":"idle"}'
  page "session_message_s2_--limit_100_--offset_0" false '[{"type":"agent","content":{"rawPayload":{"event":{"type":"item.completed","item":{"type":"reasoning","text":"hmm"}}}}},{"type":"agent","content":{"rawPayload":{"event":{"type":"item.completed","item":{"type":"agentMessage","text":"pong"}}}}},{"type":"agent","content":{"rawPayload":{"event":{"type":"turn.completed"}}}}]'
  assert_eq "pong" "$("$scripts/last-report.sh" s2)" "codex report"
}

test_last_report_prints_nothing_until_the_latest_request_has_a_reply() {
  fake_conductor "$1"
  answer "session_status_s3" '{"status":"idle"}'
  page "session_message_s3_--limit_100_--offset_0" false '[{"type":"userMessage","content":{"id":"m-1","message":"go"}},{"type":"agent","content":{"rawPayload":{"type":"result","subtype":"success","is_error":false,"result":"previous report"}}},{"type":"userMessage","content":{"id":"m-2","message":"next task"}}]'
  assert_eq "" "$("$scripts/last-report.sh" s3 m-2)" "report of the latest request"
}

test_last_report_is_pending_until_the_sent_message_starts() {
  fake_conductor "$1"
  answer "session_status_s7" '{"status":"idle"}'
  page "session_message_s7_--limit_100_--offset_0" false '[{"type":"userMessage","content":{"id":"m-1","message":"go"}},{"type":"agent","content":{"rawPayload":{"type":"result","subtype":"success","is_error":false,"result":"previous report"}}}]'
  assert_eq "pending: m-2" "$("$scripts/last-report.sh" s7 m-2)" "queued message"
}

test_last_report_gives_the_error_of_a_session_in_error() {
  fake_conductor "$1"
  answer "session_status_s9" '{"status":"error","errorMessage":"thread not found"}'
  assert_eq "error: thread not found" "$("$scripts/last-report.sh" s9)" "session in error"
}

test_last_report_gives_a_failure_after_the_request_from_the_status() {
  fake_conductor "$1"
  answer "session_status_s10" '{"status":"idle","lastError":"system_interrupt:shutdown","lastErrorAt":"2026-10-31T10:00:09.000Z"}'
  page "session_message_s10_--limit_100_--offset_0" false '[{"type":"userMessage","receivedAt":"2026-10-31T10:00:00.000Z","content":{"id":"m-1","message":"go"}},{"type":"agent","content":{"rawPayload":{"event":{"type":"error","message":"Reconnecting... 3/5","willRetry":true}}}}]'
  assert_eq "error: system_interrupt:shutdown" "$("$scripts/last-report.sh" s10 m-1)" "failure after the request"
  answer "session_status_s11" '{"status":"idle","lastError":"old failure","lastErrorAt":"2026-10-31T09:59:00.000Z"}'
  page "session_message_s11_--limit_100_--offset_0" false '[{"type":"userMessage","receivedAt":"2026-10-31T10:00:00.000Z","content":{"id":"m-1","message":"go"}},{"type":"agent","content":{"rawPayload":{"type":"result","subtype":"success","is_error":false,"result":"new report"}}}]'
  assert_eq "new report" "$("$scripts/last-report.sh" s11 m-1)" "failure before the request"
}

test_last_report_is_pending_while_the_session_works() {
  fake_conductor "$1"
  # A long gate run has no error and stays pending.
  answer "session_status_s12" '{"status":"working"}'
  page "session_message_s12_--limit_100_--offset_0" false '[{"type":"userMessage","receivedAt":"2026-10-31T10:00:00.000Z","content":{"id":"m-1","message":"go"}},{"type":"agent","receivedAt":"2026-10-31T10:00:10.000Z","content":{"rawPayload":{"event":{"type":"item.started","item":{"type":"commandExecution","command":"tests/run.sh"}}}}}]'
  assert_eq "pending: working" "$(LAST_REPORT_NOW=1793448000 "$scripts/last-report.sh" s12 m-1)" "working session"
  # A command start after an error shows that the session recovered.
  answer "session_status_s18" '{"status":"working"}'
  page "session_message_s18_--limit_100_--offset_0" false '[{"type":"userMessage","receivedAt":"2026-10-31T10:00:00.000Z","content":{"id":"m-1","message":"go"}},{"type":"agent","receivedAt":"2026-10-31T10:00:05.000Z","content":{"rawPayload":{"event":{"type":"error","willRetry":true,"message":"Reconnecting... 1/5","additionalDetails":"exceeded retry limit, last status: 429 Too Many Requests"}}}},{"type":"agent","receivedAt":"2026-10-31T10:00:10.000Z","content":{"rawPayload":{"event":{"type":"item.started","item":{"type":"commandExecution","command":"tests/run.sh"}}}}}]'
  assert_eq "pending: working" "$(LAST_REPORT_NOW=1793448000 "$scripts/last-report.sh" s18 m-1)" "recovered working session"
  # A failed transcript read keeps its cause, warns, and leaves the working
  # session pending.
  answer "session_status_s19" '{"status":"working"}'
  local out expected status=0
  out="$(LAST_REPORT_NOW=1793448000 "$scripts/last-report.sh" s19 m-1 2> "$1/stderr")" || status=$?
  assert_eq 0 "$status" "transcript failure exit status"
  assert_eq "pending: working" "$out" "working session without a transcript"
  expected="$(printf '%s\n%s' "fake conductor: no answer for 'session_message_s19_--limit_100_--offset_0'" \
    "warning: session s19: transcript could not be read; stall check did not run")"
  assert_eq "$expected" "$(cat "$1/stderr")" "cause and warning"
}

test_last_report_gives_a_stall_when_a_working_session_ends_on_an_error() {
  fake_conductor "$1"
  answer "session_status_s16" '{"status":"working"}'
  page "session_message_s16_--limit_100_--offset_0" true '[{"type":"userMessage","receivedAt":"2026-10-31T10:00:00.000Z","content":{"id":"m-1","message":"go"}},{"type":"agent","receivedAt":"2026-10-31T10:00:30.000Z","content":{"rawPayload":{"event":{"type":"item.completed","item":{"type":"agentMessage","text":"starting work"}}}}}]'
  page "session_message_s16_--limit_100_--offset_2" false '[{"type":"agent","receivedAt":"2026-10-31T10:01:00.000Z","content":{"rawPayload":{"event":{"type":"error","willRetry":true,"message":"Reconnecting... 1/5","additionalDetails":"exceeded retry limit, last status: 429 Too Many Requests"}}}}]'
  answer "session_status_s17" '{"status":"working"}'
  page "session_message_s17_--limit_100_--offset_0" false '[{"type":"userMessage","receivedAt":"2026-10-31T10:00:00.000Z","content":{"id":"m-1","message":"go"}},{"type":"agent","receivedAt":"2026-10-31T10:01:00.000Z","content":{"rawPayload":{"type":"result","is_error":true,"result":"API Error: 529 Overloaded"}}}]'
  # The status request m-2 waits behind the stalled turn, so it is not in the transcript.
  assert_eq "pending: working" "$(LAST_REPORT_NOW=1793441759 "$scripts/last-report.sh" s16 m-2)" "codex error at 899 seconds"
  assert_eq "error: stalled: Reconnecting... 1/5: exceeded retry limit, last status: 429 Too Many Requests" "$(LAST_REPORT_NOW=1793441760 "$scripts/last-report.sh" s16 m-2)" "codex error at 900 seconds"
  assert_eq "error: stalled: API Error: 529 Overloaded" "$(LAST_REPORT_NOW=1793441760 "$scripts/last-report.sh" s17 m-1)" "claude error at 900 seconds"
}

test_last_report_waits_while_background_tasks_run() {
  fake_conductor "$1"
  answer "session_status_s13" '{"status":"idle"}'
  page "session_message_s13_--limit_100_--offset_0" false '[{"type":"userMessage","content":{"id":"m-1","message":"go"}},{"type":"agent","content":{"rawPayload":{"type":"system","subtype":"background_tasks_changed","tasks":[{"task_id":"t1","task_type":"local_agent","description":"Check finding 14"}]}}},{"type":"agent","content":{"rawPayload":{"type":"result","subtype":"success","is_error":false,"result":"progress text"}}}]'
  assert_eq "waiting: Check finding 14" "$("$scripts/last-report.sh" s13 m-1)" "live task"
}

test_last_report_is_pending_while_the_agent_still_runs() {
  fake_conductor "$1"
  # The agent state of the Agent SDK stays running between the turns of one
  # request, while Conductor already shows the session as idle.
  local request='[{"type":"userMessage","receivedAt":"2026-10-31T10:00:00.000Z","content":{"id":"m-1","message":"go"}},{"type":"agent","receivedAt":"2026-10-31T10:00:01.000Z","content":{"rawPayload":{"type":"system","subtype":"session_state_changed","state":"running"}}},{"type":"agent","receivedAt":"2026-10-31T10:00:02.000Z","content":{"rawPayload":{"type":"system","subtype":"background_tasks_changed","tasks":[{"task_id":"t1","description":"Check finding 14"}]}}},{"type":"agent","receivedAt":"2026-10-31T10:00:03.000Z","content":{"rawPayload":{"type":"result","subtype":"success","is_error":false,"result":"progress text"}}},{"type":"agent","receivedAt":"2026-10-31T10:01:00.000Z","content":{"rawPayload":{"type":"system","subtype":"background_tasks_changed","tasks":[]}}}'
  answer "session_status_s15" '{"status":"idle"}'
  page "session_message_s15_--limit_100_--offset_0" false "$request]"
  # 10:02:00 UTC: one minute after the last event.
  assert_eq "pending: working" "$(LAST_REPORT_NOW=1793440920 "$scripts/last-report.sh" s15 m-1)" "agent still running"
  # 11:00:00 UTC: no event for 59 minutes, so the turn has stopped.
  assert_eq "progress text" "$(LAST_REPORT_NOW=1793444400 "$scripts/last-report.sh" s15 m-1)" "stopped turn"
  answer "session_status_s14" '{"status":"idle"}'
  page "session_message_s14_--limit_100_--offset_0" false "$request"',{"type":"agent","receivedAt":"2026-10-31T10:01:30.000Z","content":{"rawPayload":{"type":"result","subtype":"success","is_error":false,"result":"final report"}}},{"type":"agent","receivedAt":"2026-10-31T10:01:31.000Z","content":{"rawPayload":{"type":"system","subtype":"session_state_changed","state":"idle"}}}]'
  assert_eq "final report" "$(LAST_REPORT_NOW=1793440920 "$scripts/last-report.sh" s14 m-1)" "agent done"
}

test_last_report_reads_a_page_larger_than_one_argument() {
  fake_conductor "$1"
  answer "session_status_s4" '{"status":"idle"}'
  # Linux caps one command argument at 128 KiB. A real transcript page had 574 KB.
  local big out
  big="$(head -c 200000 /dev/zero | tr '\0' x)"
  page "session_message_s4_--limit_100_--offset_0" false "[{\"type\":\"agent\",\"content\":{\"rawPayload\":{\"type\":\"result\",\"is_error\":false,\"result\":\"$big\"}}}]"
  out="$("$scripts/last-report.sh" s4)"
  assert_eq 200000 "${#out}" "report length"
}

test_last_report_needs_a_session_id() {
  fake_conductor "$1"
  local status=0
  "$scripts/last-report.sh" > /dev/null 2>&1 || status=$?
  assert_eq 2 "$status" "exit status"
}

test_list_all_stops_on_an_empty_page_that_claims_more() {
  fake_conductor "$1"
  page "workspace_session_w-loop_--limit_100_--offset_0" true '[{"id":"ses-1","name":"one"}]'
  page "workspace_session_w-loop_--limit_100_--offset_1" true '[]'
  # shellcheck source=skills/coordinator/scripts/conductor-pages.sh
  source "$scripts/conductor-pages.sh"
  assert_eq '[{"id":"ses-1","name":"one"}]' "$(list_all workspace session w-loop)" "items"
}

run_all_tests

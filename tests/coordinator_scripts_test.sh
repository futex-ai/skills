#!/usr/bin/env bash
# Tests for the scripts of the conductor-section-workspace-coordinator
# skill, against a fake conductor CLI that answers from files.
set -euo pipefail
# shellcheck source=tests/lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

scripts="$repo_under_test/skills/conductor-section-workspace-coordinator/scripts"

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

test_section_scan_lists_the_section_and_its_workspaces() {
  fake_conductor "$1"
  page "section_list_--limit_100_--offset_0" false '[{"id":"s-other","name":"Other","kind":"custom","workspaceIds":["w9"]},{"id":"s-perf","name":"Performance","kind":"custom","workspaceIds":["w-self","w-child","w-empty"]}]'
  page "workspace_session_w-self_--limit_100_--offset_0" false '[{"id":"ses-self","name":"coordinator"}]'
  page "workspace_session_w-child_--limit_100_--offset_0" false '[{"id":"ses-plan","name":"plan"},{"id":"ses-impl","name":"implement"}]'
  page "workspace_session_w-empty_--limit_100_--offset_0" false '[]'
  answer "session_status_ses-self" '{"status":"working"}'
  answer "session_status_ses-impl" '{"status":"idle"}'
  answer "workspace_get_w-self" '{"id":"w-self","name":"coordinator: Performance","state":"ready"}'
  answer "workspace_get_w-child" '{"id":"w-child","name":"Cache the index","state":"sleeping"}'
  answer "workspace_get_w-empty" '{"id":"w-empty","name":"Fresh","state":"initializing"}'
  local expected
  expected="$(printf 'section\ts-perf\tPerformance\nself\tw-self\tready\tses-self\tworking\tcoordinator: Performance\nmember\tw-child\tsleeping\tses-impl\tidle\tCache the index\nmember\tw-empty\tinitializing\t\t\tFresh')"
  assert_eq "$expected" "$("$scripts/section-workspaces.sh" w-self)" "scan output"
}

test_section_scan_reads_every_page_of_sections_and_sessions() {
  fake_conductor "$1"
  page "section_list_--limit_100_--offset_0" true '[{"id":"s-other","name":"Other","kind":"custom","workspaceIds":["w9"]}]'
  page "section_list_--limit_100_--offset_1" false '[{"id":"s-late","name":"Late","kind":"custom","workspaceIds":["w-self"]}]'
  page "workspace_session_w-self_--limit_100_--offset_0" true '[{"id":"ses-old","name":"old"},{"id":"ses-mid","name":"mid"}]'
  page "workspace_session_w-self_--limit_100_--offset_2" false '[{"id":"ses-new","name":"coordinator"}]'
  answer "session_status_ses-new" '{"status":"idle"}'
  answer "workspace_get_w-self" '{"id":"w-self","name":"coordinator: Late","state":"ready"}'
  local expected
  expected="$(printf 'section\ts-late\tLate\nself\tw-self\tready\tses-new\tidle\tcoordinator: Late')"
  assert_eq "$expected" "$("$scripts/section-workspaces.sh" w-self)" "scan across pages"
}

test_section_scan_takes_the_workspace_from_the_environment() {
  fake_conductor "$1"
  page "section_list_--limit_100_--offset_0" false '[{"id":"s1","name":"One","kind":"custom","workspaceIds":["w-env"]}]'
  page "workspace_session_w-env_--limit_100_--offset_0" false '[]'
  answer "workspace_get_w-env" '{"id":"w-env","name":"Env","state":"ready"}'
  local out
  out="$(CONDUCTOR_WORKSPACE_ID=w-env "$scripts/section-workspaces.sh")"
  assert_contains "$out" "$(printf 'self\tw-env\tready')" "self row"
}

test_section_scan_fails_outside_a_section() {
  fake_conductor "$1"
  page "section_list_--limit_100_--offset_0" false '[{"id":"s1","name":"One","kind":"custom","workspaceIds":["w9"]}]'
  local out status=0
  out="$("$scripts/section-workspaces.sh" w-self 2>&1)" || status=$?
  assert_eq 1 "$status" "exit status"
  assert_contains "$out" "workspace w-self is in no section" "message"
}

test_section_scan_needs_a_workspace_id() {
  fake_conductor "$1"
  local out status=0
  out="$(env -u CONDUCTOR_WORKSPACE_ID "$scripts/section-workspaces.sh" 2>&1)" || status=$?
  assert_eq 2 "$status" "exit status"
  assert_contains "$out" "no workspace id" "message"
}

test_last_report_keeps_the_last_good_result_across_pages() {
  fake_conductor "$1"
  page "session_message_s1_--limit_100_--offset_0" true '[{"type":"userMessage","content":{"message":"go"}},{"type":"agent","content":{"rawPayload":{"type":"assistant","message":{"content":[{"type":"text","text":"thinking aloud"}]}}}},{"type":"agent","content":{"rawPayload":{"type":"result","subtype":"success","is_error":false,"result":"first report"}}}]'
  page "session_message_s1_--limit_100_--offset_3" false '[{"type":"agent","content":{"rawPayload":{"type":"result","subtype":"success","is_error":true,"result":"API Error: 429"}}}]'
  assert_eq "first report" "$("$scripts/last-report.sh" s1)" "claude report"
}

test_last_report_reads_a_codex_session() {
  fake_conductor "$1"
  page "session_message_s2_--limit_100_--offset_0" false '[{"type":"agent","content":{"rawPayload":{"event":{"type":"item.completed","item":{"type":"reasoning","text":"hmm"}}}}},{"type":"agent","content":{"rawPayload":{"event":{"type":"item.completed","item":{"type":"agentMessage","text":"pong"}}}}},{"type":"agent","content":{"rawPayload":{"event":{"type":"turn.completed"}}}}]'
  assert_eq "pong" "$("$scripts/last-report.sh" s2)" "codex report"
}

test_last_report_prints_nothing_without_agent_text() {
  fake_conductor "$1"
  page "session_message_s3_--limit_100_--offset_0" false '[{"type":"userMessage","content":{"message":"go"}}]'
  assert_eq "" "$("$scripts/last-report.sh" s3)" "empty report"
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
  # shellcheck source=skills/conductor-section-workspace-coordinator/scripts/conductor-pages.sh
  source "$scripts/conductor-pages.sh"
  assert_eq '[{"id":"ses-1","name":"one"}]' "$(list_all workspace session w-loop)" "items"
}

run_all_tests

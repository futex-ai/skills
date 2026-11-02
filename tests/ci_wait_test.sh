#!/usr/bin/env bash
# Tests for skills/finish-work/scripts/ci-wait.sh: running and late runs,
# passing conclusions, the first failed step of each failed job, the
# deadline, the no-run grace period, and recovery from failed gh calls.
# A fake clock checks the grace period for late runs and reruns.
set -euo pipefail
# shellcheck source=tests/lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

if ! command -v jq >/dev/null 2>&1; then
  echo "SKIP ci_wait_test.sh: jq is not installed"
  exit 0
fi

ci_wait() { "$repo_under_test/skills/finish-work/scripts/ci-wait.sh" --interval 0 "$@"; }

make_ci_fixture() {  # make_ci_fixture <dir>: one commit and a scenario-backed gh
  ci_scenario="$1/scenario"
  mkdir -p "$ci_scenario" "$1/bin"
  git_t init -q "$1/repo"
  git_t -C "$1/repo" commit -q --allow-empty -m "initial commit"
  export CI_WAIT_SCENARIO="$ci_scenario"
  export PATH="$1/bin:$PATH"
  cat > "$1/bin/gh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
scenario="$CI_WAIT_SCENARIO"
if [[ "${1-}" == -R ]]; then
  printf '%s\n' "$2" > "$scenario/repo"
  shift 2
fi
[[ "${1-}" == run ]] || exit 1
command="$2"
shift 2
id=""
if [[ "$command" == view ]]; then id="$1"; shift; fi
filter="."
while (( $# > 0 )); do
  case "$1" in
    --commit) printf '%s\n' "$2" > "$scenario/commit"; shift 2 ;;
    --jq) filter="$2"; shift 2 ;;
    --limit|--json) shift 2 ;;
    *) echo "unexpected gh argument: $1" >&2; exit 1 ;;
  esac
done
case "$command" in
  list)
    count=0
    if [[ -f "$scenario/count" ]]; then read -r count < "$scenario/count"; fi
    count=$((count + 1))
    printf '%s\n' "$count" > "$scenario/count"
    if [[ -f "$scenario/fail-$count" ]]; then
      echo "simulated gh error on call $count" >&2
      exit 1
    fi
    index="$count"
    while (( index > 1 )) && [[ ! -f "$scenario/list-$index.json" ]]; do
      index=$((index - 1))
    done
    file="$scenario/list-$index.json"
    ;;
  view) file="$scenario/jobs-$id.json" ;;
  *) echo "unexpected gh command: $command" >&2; exit 1 ;;
esac
jq -r "$filter" "$file"
EOF
  cat > "$1/bin/date" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
if [[ $# != 1 || "$1" != +%s ]]; then
  echo "unexpected date arguments: $*" >&2
  exit 1
fi
now=0
if [[ -f "$CI_WAIT_SCENARIO/clock" ]]; then
  read -r now < "$CI_WAIT_SCENARIO/clock"
fi
printf '%s\n' "$now"
printf '%s\n' "$((now + 10))" > "$CI_WAIT_SCENARIO/clock"
EOF
  chmod +x "$1/bin/gh" "$1/bin/date"
  cd "$1/repo"
}

run_json() {  # run_json <id> <workflow> <status> <conclusion>
  printf '{"databaseId":%s,"workflowName":"%s","status":"%s","conclusion":"%s","url":"https://example.test/runs/%s"}' \
    "$1" "$2" "$3" "$4" "$1"
}

write_list() {  # write_list <poll> [run-json...]
  local poll="$1"
  shift
  (IFS=,; printf '[%s]\n' "$*") > "$ci_scenario/list-$poll.json"
}

test_waits_for_running_and_late_runs() {
  # Break: stop at the first complete poll, or count skipped as a failure.
  local out status=0
  make_ci_fixture "$1"
  write_list 1 "$(run_json 11 check in_progress '')" "$(run_json 12 optional completed skipped)"
  write_list 2 "$(run_json 11 check completed success)" "$(run_json 12 optional completed skipped)"
  write_list 3 "$(run_json 13 late queued '')" "$(run_json 12 optional completed skipped)" "$(run_json 11 check completed success)"
  write_list 4 "$(run_json 11 check completed success)" "$(run_json 12 optional completed skipped)" "$(run_json 13 late completed neutral)"
  write_list 5 "$(run_json 13 late completed neutral)" "$(run_json 11 check completed success)" "$(run_json 12 optional completed skipped)"
  printf '{"jobs":[]}\n' > "$ci_scenario/jobs-12.json"
  out="$(ci_wait --grace 0 2>&1)" || status=$?
  assert_eq 0 "$status" "exit status"
  assert_contains "$out" "success check https://example.test/runs/11" "completed run"
  assert_contains "$out" "skipped optional https://example.test/runs/12" "skipped run passes"
  assert_contains "$out" "neutral late https://example.test/runs/13" "late run passes"
  assert_lacks "$out" "warning:" "no gh error"
  assert_eq 5 "$(cat "$ci_scenario/count")" "two complete polls with the same runs"
  assert_eq "$(git_t rev-parse HEAD)" "$(cat "$ci_scenario/commit")" "resolved default commit"
}

test_names_the_first_failed_step_of_each_failed_job() {
  # Break: select the wrong jobs from gh run view.
  local out status=0
  make_ci_fixture "$1"
  write_list 1 "$(run_json 21 CI completed failure)"
  cat > "$ci_scenario/jobs-21.json" <<'EOF'
{"jobs":[
  {"name":"Rust tests","conclusion":"failure","steps":[
    {"name":"Checkout","conclusion":"success"},
    {"name":"Build HMRC LTS","conclusion":"failure"},
    {"name":"Later failure","conclusion":"failure"}]},
  {"name":"Verify","conclusion":"failure","steps":[
    {"name":"Verify required jobs","conclusion":"failure"}]},
  {"name":"Passed job","conclusion":"success","steps":[]},
  {"name":"Skipped job","conclusion":"skipped","steps":[]},
  {"name":"Neutral job","conclusion":"neutral","steps":[]}
]}
EOF
  out="$(ci_wait --grace 0 2>&1)" || status=$?
  assert_eq 1 "$status" "exit status"
  assert_contains "$out" "failure CI https://example.test/runs/21" "failed run"
  assert_contains "$out" "Rust tests: Build HMRC LTS" "first Rust failure"
  assert_contains "$out" "Verify: Verify required jobs" "first Verify failure"
  assert_lacks "$out" "Later failure" "only the first failed step"
  assert_lacks "$out" "Passed job" "successful jobs excluded"
  assert_lacks "$out" "Skipped job" "skipped jobs excluded"
  assert_lacks "$out" "Neutral job" "neutral jobs excluded"
}

test_stops_at_the_deadline_with_a_pending_run() {
  # Break: ignore the deadline and wait for the later completed run.
  local out status=0
  make_ci_fixture "$1"
  write_list 1 "$(run_json 31 check pending '')"
  write_list 2 "$(run_json 31 check completed success)"
  out="$(ci_wait --timeout 0 2>&1)" || status=$?
  assert_eq 2 "$status" "pending run at the deadline"
  assert_eq 1 "$(cat "$ci_scenario/count")" "no poll after the deadline"
  assert_contains "$out" "https://example.test/runs/31" "pending run URL"
}

test_reports_no_run_after_the_grace_period() {
  # Break: report a push without CI as a pass.
  local out status=0
  make_ci_fixture "$1"
  write_list 1
  out="$(ci_wait --grace 0 2>&1)" || status=$?
  assert_eq 3 "$status" "no-run exit status"
  assert_contains "$out" "no CI run for $(git_t rev-parse HEAD)" "no-run message"
}

test_polls_again_after_a_failed_gh_call() {
  # Break: stop after one gh error.
  local out status=0
  make_ci_fixture "$1"
  write_list 1 "$(run_json 51 check completed success)"
  touch "$ci_scenario/fail-1"
  out="$(ci_wait --grace 0 2>&1)" || status=$?
  assert_eq 0 "$status" "recovered exit status"
  assert_contains "$out" "warning:" "gh failure warning"
  assert_contains "$out" "simulated gh error on call 1" "gh diagnostic"
  assert_contains "$out" "success check https://example.test/runs/51" "recovered result"
  assert_eq 3 "$(cat "$ci_scenario/count")" "retry and two completed polls"
}

test_stops_after_three_failed_gh_calls() {
  # Break: retry without a limit and reach the later success response.
  local out status=0
  make_ci_fixture "$1"
  write_list 1 "$(run_json 61 check completed success)"
  touch "$ci_scenario/fail-1" "$ci_scenario/fail-2" "$ci_scenario/fail-3"
  out="$(ci_wait 2>&1)" || status=$?
  assert_eq 4 "$status" "three failed gh calls"
  assert_eq 3 "$(cat "$ci_scenario/count")" "stop after the third gh error"
  assert_contains "$out" "warning:" "gh failure warning"
  assert_contains "$out" "simulated gh error on call 3" "third gh diagnostic"
}

test_waits_for_a_late_pull_request_run() {
  # Break: stop after two equal complete polls before the pull request run.
  local out status=0
  make_ci_fixture "$1"
  write_list 1 "$(run_json 71 push completed success)"
  write_list 2 "$(run_json 71 push completed success)"
  write_list 3 "$(run_json 71 push completed success)" "$(run_json 72 pull_request queued '')"
  write_list 4 "$(run_json 71 push completed success)" "$(run_json 72 pull_request completed success)"
  out="$(ci_wait --grace 30 2>&1)" || status=$?
  assert_eq 0 "$status" "exit status"
  assert_contains "$out" "success pull_request https://example.test/runs/72" "late pull request run"
}

test_waits_for_a_late_workflow_run() {
  # Break: stop after two equal complete polls before the workflow_run run.
  local out status=0
  make_ci_fixture "$1"
  write_list 1 "$(run_json 81 CI completed success)"
  write_list 2 "$(run_json 81 CI completed success)"
  write_list 3 "$(run_json 81 CI completed success)" "$(run_json 82 workflow_run queued '')"
  write_list 4 "$(run_json 81 CI completed success)" "$(run_json 82 workflow_run completed failure)"
  cat > "$ci_scenario/jobs-82.json" <<'EOF'
{"jobs":[{"name":"Deploy","conclusion":"failure","steps":[
  {"name":"Deploy application","conclusion":"failure"}]}]}
EOF
  out="$(ci_wait --grace 30 2>&1)" || status=$?
  assert_eq 1 "$status" "late workflow_run exit status"
  assert_contains "$out" "failure workflow_run https://example.test/runs/82" "late workflow_run result"
  assert_contains "$out" "Deploy: Deploy application" "late workflow_run failed job"
}

test_waits_for_a_rerun_with_the_same_id() {
  # Break: compare only IDs, so a rerun does not restart the complete-list grace.
  local out status=0
  make_ci_fixture "$1"
  write_list 1 "$(run_json 91 CI completed failure)"
  write_list 2 "$(run_json 91 CI completed failure)"
  write_list 3 "$(run_json 91 CI in_progress '')"
  write_list 4 "$(run_json 91 CI completed success)"
  printf '{"jobs":[]}\n' > "$ci_scenario/jobs-91.json"
  out="$(ci_wait --grace 30 2>&1)" || status=$?
  assert_eq 0 "$status" "rerun exit status"
  assert_contains "$out" "success CI https://example.test/runs/91" "rerun result"
  assert_lacks "$out" "failure CI" "old rerun result excluded"
  # The clock advances by 10. Completion at poll 4 needs three more polls.
  assert_eq 7 "$(cat "$ci_scenario/count")" "complete-list grace restarts after a rerun"
}

run_all_tests

#!/usr/bin/env bash
# Tests for skills/plans/scripts/follow-ups.sh: the order by severity, the
# count, the empty and missing folders, and the default plans directory.
set -euo pipefail
# shellcheck source=tests/lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

follow_ups() { "$repo_under_test/skills/plans/scripts/follow-ups.sh" "$@"; }

write_item() {  # write_item <dir> <name> <title> <severity line> <kind line>
  mkdir -p "$1/follow-ups"
  printf '# %s\n\n%s\n%s\n- **Reason:** It waits.\n' "$3" "$4" "$5" > "$1/follow-ups/$2.md"
}

test_lists_items_high_first_with_the_count() {
  local plans="$1/plans" out expected
  write_item "$plans" low "Typo in help text" "- **Severity:** Low. **Effort:** Small." "- **Kind:** Fix after merge."
  write_item "$plans" high "Retry loop has no limit" "- **Severity:** High. **Effort:** Medium." "- **Kind:** Needs decision."
  write_item "$plans" medium "Port reuse in the harness" "- **Severity:** Medium. **Effort:** Large." "- **Kind:** Outside the scope."
  write_item "$plans" vague "Smoke test after deploy" "- **Effort:** Small." "- **Kind:** Post-merge task."
  out="$(follow_ups "$plans")"
  expected="High    $plans/follow-ups/high.md  Retry loop has no limit  [Needs decision]
Medium  $plans/follow-ups/medium.md  Port reuse in the harness  [Outside the scope]
Low     $plans/follow-ups/low.md  Typo in help text  [Fix after merge]
Unknown $plans/follow-ups/vague.md  Smoke test after deploy  [Post-merge task]
open follow-up items: 4"
  assert_eq "$expected" "$out" "listing"
}

test_orders_items_of_one_severity_by_path() {
  local plans="$1/plans" out
  write_item "$plans" b-second "Second" "- **Severity:** Low. **Effort:** Small." "- **Kind:** Fix after merge."
  write_item "$plans" a-first "First" "- **Severity:** Low. **Effort:** Small." "- **Kind:** Fix after merge."
  out="$(follow_ups "$plans")"
  assert_eq "Low     $plans/follow-ups/a-first.md  First  [Fix after merge]" "$(sed -n 1p <<< "$out")" "first line"
  assert_eq "Low     $plans/follow-ups/b-second.md  Second  [Fix after merge]" "$(sed -n 2p <<< "$out")" "second line"
}

test_marks_an_item_without_title_or_kind() {
  local plans="$1/plans"
  mkdir -p "$plans/follow-ups"
  printf -- '- **Severity:** Medium. **Effort:** Small.\n' > "$plans/follow-ups/bare.md"
  assert_contains "$(follow_ups "$plans")" "Medium  $plans/follow-ups/bare.md  No title  [No kind]" "listing"
}

test_ignores_files_that_are_not_markdown() {
  local plans="$1/plans"
  write_item "$plans" real "Real item" "- **Severity:** Low. **Effort:** Small." "- **Kind:** Fix after merge."
  touch "$plans/follow-ups/.gitkeep" "$plans/follow-ups/notes.txt"
  assert_contains "$(follow_ups "$plans")" "open follow-up items: 1" "count"
}

test_reports_no_items_without_the_folder() {
  mkdir -p "$1/plans"
  assert_eq "no follow-up items" "$(follow_ups "$1/plans")" "output"
}

test_reports_no_items_for_an_empty_folder() {
  mkdir -p "$1/plans/follow-ups"
  assert_eq "no follow-up items" "$(follow_ups "$1/plans/")" "output"
}

test_fails_without_a_plans_directory() {
  local out status=0
  out="$(follow_ups "$1/missing" 2>&1)" || status=$?
  assert_eq "1" "$status" "exit status"
  assert_eq "no plans directory at $1/missing" "$out" "message"
}

test_uses_the_plans_directory_of_the_working_directory() {
  write_item "$1/plans" only "Only item" "- **Severity:** High. **Effort:** Small." "- **Kind:** Fix after merge."
  assert_contains "$(cd "$1" && follow_ups)" "High    plans/follow-ups/only.md  Only item" "listing"
}

run_all_tests

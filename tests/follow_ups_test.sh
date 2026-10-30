#!/usr/bin/env bash
# Tests for skills/plans/scripts/follow-ups.sh: the order by priority score,
# the points of each grade, the order of equal scores, the mark of a missing
# grade, the count, the empty and missing folders, and the default plans
# directory.
set -euo pipefail
# shellcheck source=tests/lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

follow_ups() { "$repo_under_test/skills/plans/scripts/follow-ups.sh" "$@"; }

write_item() {  # write_item <dir> <name> <title> <grades line> <kind line>
  mkdir -p "$1/follow-ups"
  printf '# %s\n\n%s\n%s\n- **Reason:** It waits.\n' "$3" "$4" "$5" > "$1/follow-ups/$2.md"
}

test_lists_items_by_score_with_the_count() {
  local plans="$1/plans" out expected
  write_item "$plans" typo "Typo in help text" "- **Severity:** Low. **Effort:** Small. **Confidence:** High. **Harder later:** No." "- **Kind:** Fix after merge."
  write_item "$plans" retry "Retry loop has no limit" "- **Severity:** High. **Effort:** Medium. **Confidence:** High. **Harder later:** No." "- **Kind:** Needs decision."
  write_item "$plans" port "Port reuse in the harness" "- **Severity:** Medium. **Effort:** Large. **Confidence:** Medium. **Harder later:** No." "- **Kind:** Outside the scope."
  write_item "$plans" dates "Stored dates lose their zone" "- **Severity:** Medium. **Effort:** Small. **Confidence:** High. **Harder later:** Yes." "- **Kind:** Post-merge task."
  out="$(follow_ups "$plans")"
  expected=" 8/10  Medium  $plans/follow-ups/dates.md  Stored dates lose their zone  [Post-merge task]
 7/10  High    $plans/follow-ups/retry.md  Retry loop has no limit  [Needs decision]
 4/10  Low     $plans/follow-ups/typo.md  Typo in help text  [Fix after merge]
 3/10  Medium  $plans/follow-ups/port.md  Port reuse in the harness  [Outside the scope]
open follow-up items: 4"
  assert_eq "$expected" "$out" "listing"
}

test_adds_the_points_of_each_grade() {
  local plans="$1/plans" expected grades score
  while IFS='|' read -r expected grades; do
    rm -rf "$plans"
    write_item "$plans" item "Item" "- $grades" "- **Kind:** Fix after merge."
    score="$(follow_ups "$plans" | sed -n '1s|/10.*||p')"
    assert_eq "$expected" "${score// /}" "score of '$grades'"
  done <<'EOF'
10|**Severity:** High. **Effort:** Small. **Confidence:** High. **Harder later:** Yes.
4|**Severity:** Medium. **Effort:** Medium. **Confidence:** Medium. **Harder later:** No.
0|**Severity:** Low. **Effort:** Large. **Confidence:** Low. **Harder later:** No.
6|**Severity:** High. **Likelihood:** Common. **Effort:** Large. **Confidence:** High. **Harder later:** No.
4|**Severity:** High. **Likelihood:** Rare. **Effort:** Large. **Confidence:** High. **Harder later:** No.
3|**Severity:** Medium. **Likelihood:** Rare. **Effort:** Large. **Confidence:** High. **Harder later:** No.
8|**Severity:** High (estimate). **Likelihood:** Rare (estimate). **Effort:** Small (estimate). **Confidence:** High. **Harder later:** Yes, because each new record needs a migration.
EOF
}

test_orders_items_of_one_score_by_severity_then_path() {
  local plans="$1/plans" out
  write_item "$plans" b-low "Second low" "- **Severity:** Low. **Effort:** Small. **Confidence:** High. **Harder later:** No." "- **Kind:** Fix after merge."
  write_item "$plans" c-high "High item" "- **Severity:** High. **Effort:** Large. **Confidence:** Low. **Harder later:** No." "- **Kind:** Fix after merge."
  write_item "$plans" a-low "First low" "- **Severity:** Low. **Effort:** Small. **Confidence:** High. **Harder later:** No." "- **Kind:** Fix after merge."
  out="$(follow_ups "$plans")"
  assert_eq " 4/10  High    $plans/follow-ups/c-high.md  High item  [Fix after merge]" "$(sed -n 1p <<< "$out")" "first line"
  assert_eq " 4/10  Low     $plans/follow-ups/a-low.md  First low  [Fix after merge]" "$(sed -n 2p <<< "$out")" "second line"
  assert_eq " 4/10  Low     $plans/follow-ups/b-low.md  Second low  [Fix after merge]" "$(sed -n 3p <<< "$out")" "third line"
}

test_marks_a_score_that_uses_a_default_grade() {
  local plans="$1/plans" out expected
  write_item "$plans" old "Item without the new grades" "- **Severity:** Medium. **Effort:** Small." "- **Kind:** Fix after merge."
  write_item "$plans" odd "Grades off the scale" "- **Severity:** Critical. **Effort:** Tiny. **Confidence:** Sure. **Harder later:** Maybe." "- **Kind:** Fix after merge."
  out="$(follow_ups "$plans")"
  expected=" 5/10? Medium  $plans/follow-ups/old.md  Item without the new grades  [Fix after merge]
 4/10? Unknown $plans/follow-ups/odd.md  Grades off the scale  [Fix after merge]
? marks a score that uses a default for a missing grade.
open follow-up items: 2"
  assert_eq "$expected" "$out" "listing"
}

test_marks_an_item_without_title_or_kind() {
  local plans="$1/plans"
  mkdir -p "$plans/follow-ups"
  printf -- '- **Severity:** Medium. **Effort:** Small. **Confidence:** High. **Harder later:** No.\n' > "$plans/follow-ups/bare.md"
  assert_contains "$(follow_ups "$plans")" " 6/10  Medium  $plans/follow-ups/bare.md  No title  [No kind]" "listing"
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

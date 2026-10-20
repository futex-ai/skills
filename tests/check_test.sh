#!/usr/bin/env bash
# Tests for scripts/check.sh: the warning for a SKILL.md sentence of more
# than 20 words, the prose that the scan skips, and the exit status.
set -euo pipefail
# shellcheck source=tests/lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

words() {  # words <n>: the words w1 to w<n>, without punctuation
  local i text="w1"
  for (( i = 2; i <= $1; i++ )); do text+=" w$i"; done
  printf '%s' "$text"
}

skill_md() {  # skill_md <dir> <name>: a SKILL.md with the body from stdin, which starts on line 5
  mkdir -p "$1/skills/$2"
  {
    printf -- '---\nname: %s\ndescription: Use when you test %s.\n---\n' "$2" "$2"
    cat
  } > "$1/skills/$2/SKILL.md"
}

check() {  # check <dir>: run a copy of scripts/check.sh in <dir>; sets output and status
  [[ -d "$1/scripts" ]] || cp -R "$repo_under_test/scripts" "$1/"
  status=0
  output="$("$1/scripts/check.sh" 2>&1)" || status=$?
}

warning_count() { printf '%s\n' "$output" | grep -c 'sentence has' || true; }

test_a_sentence_over_twenty_words_warns() {
  skill_md "$1" alpha <<EOF
$(words 21).
$(words 20).
EOF
  check "$1"
  assert_eq 0 "$status" "exit status"
  assert_contains "$output" "warning: alpha: SKILL.md:5: sentence has 21 words (max 20): w1 w2 w3 w4 w5 w6 w7 w8 ..." "warning"
  assert_eq 1 "$(warning_count)" "warnings"
  assert_contains "$output" "all skills valid" "result"
}

test_a_wrapped_sentence_warns_once_at_its_first_line() {
  skill_md "$1" alpha <<EOF
$(words 10). $(words 10).
$(words 4). $(words 11)
$(words 11).
EOF
  check "$1"
  assert_eq 1 "$(warning_count)" "warnings"
  assert_contains "$output" "alpha: SKILL.md:6: sentence has 22 words" "warning"
}

test_list_items_are_not_joined() {
  skill_md "$1" alpha <<EOF
- [ ] $(words 21).
- $(words 12)
- $(words 12)
1. $(words 12)
2) $(words 12)
- $(words 11)
  $(words 11).
EOF
  check "$1"
  assert_eq 2 "$(warning_count)" "warnings"
  assert_contains "$output" "alpha: SKILL.md:5: sentence has 21 words (max 20): w1 w2" "checkbox item"
  assert_contains "$output" "alpha: SKILL.md:10: sentence has 22 words" "item with a second line"
}

test_frontmatter_headings_tables_and_code_are_skipped() {
  mkdir -p "$1/skills/alpha"
  {
    printf -- '---\nname: alpha\ndescription: %s.\n---\n' "$(words 25)"
    cat <<EOF
# $(words 25)

| $(words 25). | cell |
| --- | --- |

\`\`\`text
$(words 25).
\`\`\`

~~~
$(words 25).
~~~

\`\`\`\`markdown
\`\`\`sh
$(words 25).
\`\`\`
$(words 25).
\`\`\`\`
$(words 21).
EOF
  } > "$1/skills/alpha/SKILL.md"
  check "$1"
  assert_eq 0 "$status" "exit status"
  assert_eq 1 "$(warning_count)" "warnings"
  assert_contains "$output" "alpha: SKILL.md:24: sentence has 21 words" "prose after the fences"
}

test_sentences_split_after_closing_marks() {
  skill_md "$1" alpha <<EOF
($(words 15).) $(words 15).
"$(words 15)." $(words 15)? $(words 15)!
\`$(words 15).\` $(words 15) \`code\`. $(words 15).
$(words 10) SKILL.md $(words 10).
EOF
  check "$1"
  assert_eq 1 "$(warning_count)" "warnings"
  assert_contains "$output" "alpha: SKILL.md:8: sentence has 21 words" "a period inside a word"
}

test_a_missing_skill_md_still_fails() {
  skill_md "$1" alpha <<EOF
$(words 21).
EOF
  mkdir -p "$1/skills/beta"
  check "$1"
  assert_eq 1 "$status" "exit status with a warning"
  assert_contains "$output" "error: beta: missing SKILL.md" "error"
  assert_eq 1 "$(warning_count)" "warnings"
  skill_md "$1" alpha <<< "$(words 5)."
  check "$1"
  assert_eq 1 "$status" "exit status without a warning"
  assert_eq 0 "$(warning_count)" "no warnings"
}

test_a_failed_scan_warns_and_the_run_passes() {
  mkdir -p "$1/bin"
  # The fake awk fails the sentence scan, the only call with max=. It passes
  # every other call to the real awk.
  cat > "$1/bin/awk" <<EOF
#!/usr/bin/env bash
for arg in "\$@"; do
  if [[ "\$arg" == max=* ]]; then echo "awk: scan failed on purpose" >&2; exit 2; fi
done
exec "$(command -v awk)" "\$@"
EOF
  chmod +x "$1/bin/awk"
  skill_md "$1" alpha <<EOF
$(words 21).
EOF
  PATH="$1/bin:$PATH" check "$1"
  assert_eq 0 "$status" "exit status"
  assert_contains "$output" "warning: alpha: the sentence scan failed" "warning"
  assert_contains "$output" "awk: scan failed on purpose" "awk error"
  assert_eq 0 "$(warning_count)" "sentence warnings"
  assert_contains "$output" "all skills valid" "result"
}

run_all_tests

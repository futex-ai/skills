#!/usr/bin/env bash
# The extraction and the summary for tests/behavior/run.sh. run.sh sources
# this file; do not run it. It uses the variables that run.sh sets:
# run_dir, agents, reps, model, sc_skill, sc_expect, and sc_forbid.
# shellcheck shell=bash disable=SC2154

jsonl() {  # jsonl <file> <filter>: run a jq filter over each valid JSON line
  jq -R -r "fromjson? | $2" "$1"
}

extract_actions() {  # extract_actions <run dir> <agent>: write actions.md and final.md
  local t="$1/transcript.jsonl"
  if [[ "$2" == claude ]]; then
    jsonl "$t" 'select(.type == "assistant") | .message.content[]?
      | if .type == "text" then "> " + .text
        elif .type == "tool_use" then "$ " + .name + ": "
          + (if .name == "Bash" then (.input.command // "") else (.input | tostring) end)
        else empty end' > "$1/actions.md"
    jsonl "$t" 'select(.type == "result") | .result // ""' > "$1/final.md"
  else
    jsonl "$t" 'select(.type == "item.completed") | .item
      | if .type == "agent_message" then "> " + (.text // "")
        elif .type == "command_execution" then "$ " + (.command // "")
        elif .type == "file_change" then "~ " + ((.changes // []) | map(.path // "") | join(" "))
        else empty end' > "$1/actions.md"
    if [[ ! -s "$1/final.md" ]]; then
      jq -R -r -s 'split("\n") | map(fromjson?)
        | map(select(.type == "item.completed" and .item.type == "agent_message"))
        | (last | .item.text) // ""' "$t" > "$1/final.md"
    fi
  fi
}

run_loaded() {  # run_loaded <run dir> <variant>: yes or no for discovery, else -
  if [[ "$2" != discovery ]]; then echo -; return; fi
  if grep -Eq -- "\"skill\": ?\"$sc_skill\"|$sc_skill/SKILL\.md" "$1/transcript.jsonl"; then
    echo yes
  else
    echo no
  fi
}

run_hint() {  # run_hint <run dir>: PASS, FAIL, or - from the expect and forbid patterns
  local pattern
  if (( ${#sc_expect[@]} == 0 && ${#sc_forbid[@]} == 0 )); then echo -; return; fi
  for pattern in ${sc_expect[@]+"${sc_expect[@]}"}; do
    if ! grep -Eq -- "$pattern" "$1/actions.md"; then echo FAIL; return; fi
  done
  for pattern in ${sc_forbid[@]+"${sc_forbid[@]}"}; do
    if grep -Eq -- "$pattern" "$1/actions.md"; then echo FAIL; return; fi
  done
  echo PASS
}

run_cost() {  # run_cost <run dir> <agent>: the cost of the run as text, or -
  local cost
  if [[ "$2" == claude ]]; then
    cost="$(jsonl "$1/transcript.jsonl" 'select(.type == "result") | .total_cost_usd // empty' \
      | tail -n 1 | sed 's/^/$/')"
  else
    cost="$(jsonl "$1/transcript.jsonl" 'select(.type == "turn.completed")
      | ((.usage.input_tokens // 0) + (.usage.output_tokens // 0))' \
      | awk '{ s += $1 } END { if (NR) print s " tok" }')"
  fi
  printf '%s' "${cost:--}"
}

summary_start() {  # write the head of summary.md, and notes.md when it is missing
  summary_skills=""
  {
    echo "# Behavior run $(basename "$run_dir")"
    echo
    echo "- Date: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo "- Agents: ${agents[*]}"
    echo "- Reps: $reps"
    if [[ -n "$model" ]]; then echo "- Model: $model"; fi
  } > "$run_dir/summary.md"
  if [[ ! -f "$run_dir/notes.md" ]]; then
    printf '# Notes\n\nCopy each excuse verbatim, with the run that it came from.\n' > "$run_dir/notes.md"
  fi
}

summary_skill() {  # summary_skill <scenario> <skill dir>: record the skill under test
  summary_skills+="- Skill for $1: $2"$'\n'
}

summary_row() {  # summary_row <scenario> <agent> <variant> <rep> <status> <loaded> <hint> <cost>
  if ! grep -q '^| Scenario |' "$run_dir/summary.md"; then
    {
      echo
      echo "| Scenario | Agent | Variant | Rep | Status | Loaded | Hint | Cost |"
      echo "| --- | --- | --- | --- | --- | --- | --- | --- |"
    } >> "$run_dir/summary.md"
  fi
  printf '| %s | %s | %s | %s | %s | %s | %s | %s |\n' "$@" >> "$run_dir/summary.md"
}

summary_end() {  # write the foot of summary.md
  {
    echo
    printf '%s' "$summary_skills"
    echo
    echo "Hint is a regular expression over actions.md, not a verdict. Read"
    echo "every actions.md, and copy each excuse verbatim into notes.md."
  } >> "$run_dir/summary.md"
}

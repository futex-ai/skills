#!/usr/bin/env bash
# The extraction and the summary for tests/behavior/run.sh. run.sh sources
# this file; do not run it. It uses the variables that run.sh sets:
# run_dir, agents, reps, model, sc_dir, sc_skill, sc_expect, and sc_forbid.
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

found_skill() {  # found_skill <run dir>: 0 when the transcript shows the skill was loaded or read
  grep -Eq -- "\"skill\": ?\"$sc_skill\"|skills/$sc_skill([/\"' ]|$)|$sc_skill/SKILL\.md" "$1/transcript.jsonl"
}

run_loaded() {  # run_loaded <run dir> <variant>: discovery: yes or no; control: leak or -; else -
  case "$2" in
    discovery) if found_skill "$1"; then echo yes; else echo no; fi ;;
    control) if found_skill "$1"; then echo leak; else echo -; fi ;;
    *) echo - ;;
  esac
}

run_hint() {  # run_hint <run dir>: PASS or FAIL from check.sh, else from the patterns, else -
  local pattern
  if [[ -f "$sc_dir/check.sh" ]]; then
    if (cd "$1/workspace" && HOME="$1/home" bash "$sc_dir/check.sh") > "$1/check.log" 2>&1; then
      echo PASS
    else
      echo FAIL
    fi
    return
  fi
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
    echo "Hint comes from the scenario's check.sh, or from the expect and"
    echo "forbid patterns. It is not a verdict. Read every actions.md, and"
    echo "copy each excuse verbatim into notes.md."
  } >> "$run_dir/summary.md"
}

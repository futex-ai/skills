#!/usr/bin/env bash
# Scenario files and workspaces for tests/behavior/run.sh. run.sh sources
# this file; do not run it. It uses the variables that run.sh sets: repo,
# scenarios_dir, skill_dir, and variants.
#
# A scenario.md starts with frontmatter: skill (required), variants (a
# space-separated list), and any number of expect and forbid lines with
# regular expressions. The rest of the file is the prompt.
# shellcheck shell=bash disable=SC2154,SC2034

list_scenarios() {  # the scenario names, one per line
  local dir
  for dir in "$scenarios_dir"/*/; do
    if [[ -f "$dir/scenario.md" ]]; then basename "$dir"; fi
  done
  return 0
}

frontmatter() {  # frontmatter <file>: the lines between the first two --- lines
  awk 'NR == 1 { if ($0 != "---") exit; next } /^---$/ { exit } { print }' "$1"
}

body() {  # body <file>: the file without its frontmatter
  awk 'NR == 1 && $0 == "---" { skip = 1; next } skip && /^---$/ { skip = 0; next } !skip' "$1"
}

field() {  # field <text> <name>: the first "name: value" line of the text, or nothing
  printf '%s\n' "$1" | sed -n "s/^$2:[[:space:]]*//p" | head -n 1
}

load_scenario() {  # load_scenario <name>: set sc_name, sc_dir, sc_skill, sc_variants, sc_expect, sc_forbid, sc_prompt
  local file front line
  sc_name="$1"
  sc_dir="$scenarios_dir/$1"
  file="$sc_dir/scenario.md"
  if [[ ! -f "$file" ]]; then echo "unknown scenario: $1" >&2; exit 2; fi
  if [[ "$(head -n 1 "$file")" != "---" ]]; then
    echo "$1: scenario.md must start with YAML frontmatter" >&2; exit 2
  fi
  front="$(frontmatter "$file")"
  sc_skill="$(field "$front" skill)"
  if [[ -z "$sc_skill" ]]; then echo "$1: scenario.md needs a skill: line" >&2; exit 2; fi
  sc_variants="$(field "$front" variants)"
  : "${sc_variants:=control skill}"
  sc_expect=()
  sc_forbid=()
  while IFS= read -r line; do
    if [[ -n "$line" ]]; then sc_expect+=("$line"); fi
  done < <(printf '%s\n' "$front" | sed -n 's/^expect:[[:space:]]*//p')
  while IFS= read -r line; do
    if [[ -n "$line" ]]; then sc_forbid+=("$line"); fi
  done < <(printf '%s\n' "$front" | sed -n 's/^forbid:[[:space:]]*//p')
  sc_prompt="$(body "$file")"
}

skill_dir_for() {  # the directory of the skill under test for the loaded scenario
  local dir="${skill_dir:-$repo/skills/$sc_skill}"
  if [[ ! -f "$dir/SKILL.md" ]]; then echo "$sc_name: no SKILL.md under $dir" >&2; exit 2; fi
  printf '%s' "$dir"
}

variants_for() {  # the variants to run: the --variant options, or the scenario's list
  if (( ${#variants[@]} > 0 )); then printf '%s\n' "${variants[@]}"; else printf '%s\n' "$sc_variants"; fi
}

make_workspace() {  # make_workspace <run dir>: copy files/, then run setup.sh inside the workspace
  local ws="$1/workspace"
  mkdir -p "$ws"
  if [[ -d "$sc_dir/files" ]]; then cp -R "$sc_dir/files/." "$ws/"; fi
  if [[ -f "$sc_dir/setup.sh" ]]; then
    (cd "$ws" && HOME="$1/home" SCENARIO_DIR="$sc_dir" bash "$sc_dir/setup.sh") > "$1/setup.log" 2>&1
  fi
}

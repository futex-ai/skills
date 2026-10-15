#!/usr/bin/env bash
# Run behavior scenarios against claude -p and codex exec, and record every
# run under .context/behavior/. The runs are slow, cost money, and are not
# deterministic, so this script runs on demand only. Nothing in CI calls it.
#
# Usage: run.sh [options] [scenario...]
#   --agent <claude|codex>  run one agent; repeatable; default: each on PATH
#   --variant <name>        control, skill, or discovery; repeatable;
#                           default: the scenario's list, or control and skill
#   --reps <n>              runs for each agent and variant (default 1)
#   --skill-dir <dir>       the skill under test (default skills/<skill>)
#   --scenarios-dir <dir>   where the scenarios are (default ./scenarios)
#   --label <text>          suffix for the run directory name
#   --out <dir>             run directory (default .context/behavior/<time>)
#   --timeout <s>           limit for one agent run (default 900)
#   --budget <usd>          claude --max-budget-usd for one run (default 2)
#   --model <name>          model for both agents
#   --dry-run               prepare the workspaces and commands, run nothing
#   --list                  print the scenario names and exit
#
# A scenario is a directory under the scenarios directory with a scenario.md
# (frontmatter and prompt), an optional files/ directory that is copied into
# the workspace, and an optional setup.sh that runs inside the workspace.
# Needs jq. Uses timeout or gtimeout when one is on PATH.
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo="$(cd "$here/../.." && pwd)"
real_home="$HOME"
# shellcheck source=tests/behavior/lib/scenario.sh
source "$here/lib/scenario.sh"
# shellcheck source=tests/behavior/lib/agents.sh
source "$here/lib/agents.sh"
# shellcheck source=tests/behavior/lib/report.sh
source "$here/lib/report.sh"

agents=()
variants=()
scenarios=()
reps=1
skill_dir=""
scenarios_dir="$here/scenarios"
label=""
out=""
timeout_s=900
budget=2
model=""
dry_run=0

usage() { sed -n '2,/^set -euo/p' "$0" | sed '$d' | sed 's/^# \{0,1\}//'; }

need_value() {  # need_value <option> <value>: exit 2 when the value is missing
  if [[ -z "${2-}" ]]; then echo "$1 needs a value" >&2; exit 2; fi
}

while (( $# > 0 )); do
  case "$1" in
    --agent) need_value "$1" "${2-}"; agents+=("$2"); shift 2 ;;
    --variant) need_value "$1" "${2-}"; variants+=("$2"); shift 2 ;;
    --reps) need_value "$1" "${2-}"; reps="$2"; shift 2 ;;
    --skill-dir) need_value "$1" "${2-}"; skill_dir="$(cd "$2" && pwd)"; shift 2 ;;
    --scenarios-dir) need_value "$1" "${2-}"; scenarios_dir="$(cd "$2" && pwd)"; shift 2 ;;
    --label) need_value "$1" "${2-}"; label="$2"; shift 2 ;;
    --out) need_value "$1" "${2-}"; out="$2"; shift 2 ;;
    --timeout) need_value "$1" "${2-}"; timeout_s="$2"; shift 2 ;;
    --budget) need_value "$1" "${2-}"; budget="$2"; shift 2 ;;
    --model) need_value "$1" "${2-}"; model="$2"; shift 2 ;;
    --dry-run) dry_run=1; shift ;;
    --list) list_scenarios; exit 0 ;;
    -h|--help) usage; exit 0 ;;
    --*) echo "unknown option: $1" >&2; exit 2 ;;
    *) scenarios+=("$1"); shift ;;
  esac
done

if (( ${#agents[@]} == 0 )); then
  for agent in claude codex; do
    if command -v "$agent" > /dev/null 2>&1; then agents+=("$agent"); fi
  done
fi
if (( ${#agents[@]} == 0 )); then echo "neither claude nor codex is on PATH" >&2; exit 2; fi
for agent in "${agents[@]}"; do
  case "$agent" in claude|codex) ;; *) echo "unknown agent: $agent" >&2; exit 2 ;; esac
done
for variant in ${variants[@]+"${variants[@]}"}; do
  case "$variant" in control|skill|discovery) ;; *) echo "unknown variant: $variant" >&2; exit 2 ;; esac
done
if ! [[ "$reps" =~ ^[1-9][0-9]*$ ]]; then echo "--reps needs a positive number" >&2; exit 2; fi
if ! command -v jq > /dev/null 2>&1; then echo "jq is required" >&2; exit 2; fi
if (( ${#scenarios[@]} == 0 )); then
  while IFS= read -r name; do scenarios+=("$name"); done < <(list_scenarios)
fi
if (( ${#scenarios[@]} == 0 )); then echo "no scenarios under $scenarios_dir" >&2; exit 2; fi

run_dir="${out:-$repo/.context/behavior/$(date +%Y%m%d-%H%M%S)${label:+-$label}}"
mkdir -p "$run_dir"
run_dir="$(cd "$run_dir" && pwd)"
failures=0
summary_start

keep_run() {  # keep_run <scratch> <run dir>: move the run out of the scratch directory
  mkdir -p "$2"
  mv "$1"/* "$2"/
  rmdir "$1"
  sed -i.bak "s|$1|$2|g" "$2/command.txt" && rm -f "$2/command.txt.bak"
}

run_one() {  # run_one <agent> <variant> <rep>: one agent run of the loaded scenario
  local dir="$run_dir/$sc_name/$1-$2-$3" scratch status loaded hint cost
  # The agent works in a scratch directory outside this repository, so that
  # it cannot find the skills here by walking up from its workspace.
  scratch="$(mktemp -d "${TMPDIR:-/tmp}/behavior.XXXXXX")"
  make_home "$scratch" "$1" "$2" "$sdir"
  : > "$scratch/command.txt"
  if ! make_workspace "$scratch"; then
    keep_run "$scratch" "$dir"
    summary_row "$sc_name" "$1" "$2" "$3" "setup failed" - - -
    failures=1
    return 0
  fi
  printf '%s\n' "$sc_prompt" > "$scratch/prompt.md"
  agent_argv "$scratch" "$1" "$2"
  printf '%q ' "${argv[@]}" > "$scratch/command.txt"
  echo >> "$scratch/command.txt"
  if (( dry_run )); then
    keep_run "$scratch" "$dir"
    summary_row "$sc_name" "$1" "$2" "$3" dry-run - - -
    return 0
  fi
  status="$(run_agent "$scratch")"
  keep_run "$scratch" "$dir"
  extract_actions "$dir" "$1"
  loaded="$(run_loaded "$dir" "$2")"
  hint="$(run_hint "$dir")"
  cost="$(run_cost "$dir" "$1")"
  summary_row "$sc_name" "$1" "$2" "$3" "$status" "$loaded" "$hint" "$cost"
  if [[ "$status" != ok ]]; then failures=1; fi
}

for scenario in "${scenarios[@]}"; do
  load_scenario "$scenario"
  sdir="$(skill_dir_for)"
  summary_skill "$sc_name" "$sdir"
  for agent in "${agents[@]}"; do
    for variant in $(variants_for); do
      for (( rep = 1; rep <= reps; rep++ )); do
        echo "$sc_name $agent $variant $rep"
        run_one "$agent" "$variant" "$rep"
      done
    done
  done
done

summary_end
echo "results: $run_dir/summary.md"
exit "$failures"

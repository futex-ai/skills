#!/usr/bin/env bash
# Bring a clone of futex-ai/skills to the latest origin/main and refresh the
# links that scripts/install.sh made. Built to run unattended: it never
# resets or forces, and it leaves a clone with local changes alone.
#
# Usage: update.sh [options]
#   --hook              run as a Claude Code hook: print a notice only when
#                       skills changed since the session last heard; exit 0
#   --min-interval <s>  skip the check when the last one ran less than <s>
#                       seconds ago
#   --loop <s>          check, sleep <s> seconds, repeat; one loop per state dir
#   --detach            start the loop in the background and return
#   --stop              end the loop that --detach started
#   --max-runs <n>      stop the loop after <n> checks (for tests)
#   --timeout <s>       stop a fetch that gives no answer in <s> seconds (20)
#   --state-dir <dir>   log, stamp, locks, and session notices (default ~/.futex)
#   --branch <name>     branch to follow (default main)
#
# A skip or a failed fetch exits 0, so that a setup script can call this
# without aborting. The reason is printed and logged. A usage error exits 2.
# Tests set SKILLS_UPDATE_NOW to fix the clock that --min-interval reads.
# The lock, loop, and hook functions live in scripts/lib/.
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
script="$repo/scripts/update.sh"
mode=run
min_interval=0
interval=0
detach=0
max_runs=0
net_timeout=20
state_dir="$HOME/.futex"
branch=main

# shellcheck source=scripts/lib/update-loop.sh
source "$repo/scripts/lib/update-loop.sh"
# shellcheck source=scripts/lib/update-hook.sh
source "$repo/scripts/lib/update-hook.sh"

number() {  # number <option> <value>: print <value>, a whole number
  [[ "${2-}" =~ ^[0-9]+$ ]] || { echo "option $1 needs a whole number" >&2; exit 2; }
  printf '%s' "$2"
}

text() {  # text <option> <value>: print <value>, which must not be empty
  [[ -n "${2-}" ]] || { echo "option $1 needs a value" >&2; exit 2; }
  printf '%s' "$2"
}

while (( $# )); do
  case "$1" in
    --hook) mode=hook ;;
    --min-interval) min_interval="$(number "$1" "${2-}")"; shift ;;
    --loop) mode=loop; interval="$(number "$1" "${2-}")"; shift ;;
    --detach) detach=1 ;;
    --stop) mode=stop ;;
    --max-runs) max_runs="$(number "$1" "${2-}")"; shift ;;
    --timeout) net_timeout="$(number "$1" "${2-}")"; shift ;;
    --state-dir) state_dir="$(text "$1" "${2-}")"; shift ;;
    --branch) branch="$(text "$1" "${2-}")"; shift ;;
    *) echo "unknown option: $1" >&2; exit 2 ;;
  esac
  shift
done

log="$state_dir/skills-update.log"
stamp="$state_dir/skills-update.stamp"
check_lock="$state_dir/skills-update.lock"
loop_lock="$state_dir/skills-loop.lock"
sessions="$state_dir/sessions"
hook_input=""
updated_from=""
script_changed=0

now() { printf '%s' "${SKILLS_UPDATE_NOW:-$(date +%s)}"; }

first_line() { printf '%s' "${1%%$'\n'*}"; }

git_reason() {  # git_reason <output>: the first fatal line, or the first line
  local line
  line="$(printf '%s\n' "$1" | sed -n 's/^fatal: //p' | head -n 1)"
  printf '%s' "${line:-$(first_line "$1")}"
}

log_line() {  # log_line <text>: append one line and keep the log small
  mkdir -p "$state_dir"
  if [[ -f "$log" ]] && (( $(wc -c < "$log") > 262144 )); then
    tail -n 200 "$log" > "$log.tmp" && mv "$log.tmp" "$log"
  fi
  printf '%s %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$1" >> "$log"
}

report() {  # report <status> <detail>: log it, and print it when run by hand
  log_line "$1: $2"
  if [[ "$mode" == run ]]; then echo "$1: $2"; fi
}

limited() {  # limited <seconds> <command...>: run it, and stop it after <seconds>
  local secs="$1" pid dog status
  shift
  "$@" & pid=$!
  ( trap 'kill "$!" 2>/dev/null; exit 0' TERM; sleep "$secs" & wait "$!"; kill "$pid" 2>/dev/null ) & dog=$!
  wait "$pid" && status=0 || status=$?
  kill "$dog" 2>/dev/null || true
  wait "$dog" 2>/dev/null || true
  return "$status"
}

fetch_limited() {  # fetch the branch within --timeout; the reason goes to stdout
  local errors status
  errors="$(mktemp)"
  limited "$net_timeout" env GIT_TERMINAL_PROMPT=0 git -C "$repo" fetch --quiet origin "$branch" \
    > /dev/null 2> "$errors" && status=0 || status=$?
  if (( status == 143 )); then echo "no response within ${net_timeout}s"; fi
  cat "$errors"
  rm -f "$errors"
  return "$status"
}

check_repo() {  # one update attempt on the clone; every outcome is reported
  local head err old new status install_output line
  if ! git -C "$repo" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    report failed "$repo is not a git repository"; return 0
  fi
  head="$(git -C "$repo" symbolic-ref --short -q HEAD || true)"
  if [[ "$head" != "$branch" ]]; then
    report skipped "on branch '${head:-detached HEAD}', not $branch"; return 0
  fi
  if [[ -n "$(git -C "$repo" status --porcelain --untracked-files=no)" ]]; then
    report skipped "local changes in $repo"; return 0
  fi
  if ! err="$(fetch_limited 2>&1)"; then
    report failed "fetch from origin: $(git_reason "${err:-no response within ${net_timeout}s}")"
    return 0
  fi
  old="$(git -C "$repo" rev-parse HEAD)"
  new="$(git -C "$repo" rev-parse --verify -q "origin/$branch" || true)"
  if [[ -z "$new" ]]; then report failed "origin/$branch is missing after the fetch"; return 0; fi
  if [[ "$old" == "$new" ]]; then report up-to-date "${old:0:7}"; return 0; fi
  if ! err="$(git -C "$repo" merge --ff-only --quiet "origin/$branch" 2>&1)"; then
    report skipped "cannot fast-forward to ${new:0:7}: $(git_reason "$err")"; return 0
  fi
  if [[ "$(git -C "$repo" rev-parse HEAD)" == "$old" ]]; then
    report skipped "local $branch is ahead of origin/$branch (${new:0:7})"; return 0
  fi
  updated_from="$old"
  report updated "${old:0:7} -> ${new:0:7}"
  if ! git -C "$repo" diff --quiet "$old" "$new" -- scripts/update.sh scripts/lib; then script_changed=1; fi
  install_output="$(bash "$repo/scripts/install.sh" --quiet 2>&1)" && status=0 || status=$?
  while IFS= read -r line; do
    [[ -n "$line" ]] && log_line "install: $line"
  done <<< "$install_output"
  if (( status != 0 )); then report failed "install.sh exited with $status"; fi
}

run_check() {  # throttle, lock, check, then stamp the time of the check
  local last
  if (( min_interval > 0 )) && [[ -f "$stamp" ]]; then
    last="$(cat "$stamp" 2>/dev/null || true)"
    [[ "$last" =~ ^[0-9]+$ ]] || last=0
    if (( $(now) - last < min_interval )); then
      if [[ "$mode" == run ]]; then echo "skipped: last check $(( $(now) - last ))s ago"; fi
      return 0
    fi
  fi
  if ! lock_acquire "$check_lock"; then
    report skipped "another update is running"; return 0
  fi
  check_repo
  printf '%s\n' "$(now)" > "$stamp"
  lock_release "$check_lock"
}

main() {
  if [[ "$mode" == hook && ! -t 0 ]]; then
    IFS= read -r -d '' -t 5 hook_input || true
  fi
  if (( detach )); then run_detach; exit 0; fi
  case "$mode" in
    loop) run_loop ;;
    stop) run_stop ;;
    hook) run_check; hook_output ;;
    run) run_check ;;
  esac
  exit 0
}

main

#!/usr/bin/env bash
# Bring a clone of futex-ai/skills to the latest origin/main and refresh the
# links that scripts/install.sh made. Built to run unattended: it never
# resets or forces, and it leaves a clone with local changes alone.
#
# Usage: update.sh [options]
#   --hook              print only when skills changed, in the form that a
#                       Claude Code hook expects; exit 0 in every case
#   --min-interval <s>  skip when the last check ran less than <s> seconds ago
#   --loop <s>          check, sleep <s> seconds, repeat; one loop per state dir
#   --detach            start the loop in the background and return
#   --max-runs <n>      stop the loop after <n> checks (for tests)
#   --timeout <s>       limit for the fetch (default 20)
#   --state-dir <dir>   log, stamp, and locks (default ~/.futex)
#   --branch <name>     branch to follow (default main)
#
# A skip or a failed fetch exits 0, so that a setup script can call this
# without aborting. The reason is printed and logged. A usage error exits 2.
# Tests set SKILLS_UPDATE_NOW to fix the clock that --min-interval reads.
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
hook_input=""
updated_from=""
updated_to=""
script_changed=0
loop_args=()

now() { printf '%s' "${SKILLS_UPDATE_NOW:-$(date +%s)}"; }

first_line() { printf '%s' "${1%%$'\n'*}"; }

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

holder_alive() {  # holder_alive <pid>: 0 when <pid> is a live update.sh
  kill -0 "$1" 2>/dev/null || return 1
  command -v ps >/dev/null 2>&1 || return 0
  ps -o args= -p "$1" 2>/dev/null | grep -q 'update\.sh'
}

lock_acquire() {  # lock_acquire <dir>: 0 when this process holds the lock
  local dir="$1" pid
  mkdir -p "$state_dir"
  if mkdir "$dir" 2>/dev/null; then echo "$$" > "$dir/pid"; return 0; fi
  pid="$(cat "$dir/pid" 2>/dev/null || true)"
  if [[ "$pid" == "$$" ]]; then return 0; fi
  if [[ -n "$pid" ]]; then
    if holder_alive "$pid"; then return 1; fi
  elif [[ -z "$(find "$dir" -maxdepth 0 -mmin +1 2>/dev/null)" ]]; then
    return 1
  fi
  rm -rf "$dir"
  mkdir "$dir" 2>/dev/null || return 1
  echo "$$" > "$dir/pid"
}

lock_release() { rm -rf "$1"; }

fetch_limited() {  # fetch the branch, within --timeout when timeout exists
  if command -v timeout >/dev/null 2>&1; then
    GIT_TERMINAL_PROMPT=0 timeout "$net_timeout" git -C "$repo" fetch --quiet origin "$branch"
  else
    GIT_TERMINAL_PROMPT=0 git -C "$repo" fetch --quiet origin "$branch"
  fi
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
    report failed "fetch from origin: $(first_line "${err:-no response within ${net_timeout}s}")"
    return 0
  fi
  old="$(git -C "$repo" rev-parse HEAD)"
  new="$(git -C "$repo" rev-parse --verify -q "origin/$branch" || true)"
  if [[ -z "$new" ]]; then report failed "origin/$branch is missing after the fetch"; return 0; fi
  if [[ "$old" == "$new" ]]; then report up-to-date "${old:0:7}"; return 0; fi
  if ! err="$(git -C "$repo" merge --ff-only --quiet "origin/$branch" 2>&1)"; then
    report skipped "cannot fast-forward to ${new:0:7}: $(first_line "$err")"; return 0
  fi
  updated_from="$old"
  updated_to="$new"
  report updated "${old:0:7} -> ${new:0:7}"
  if ! git -C "$repo" diff --quiet "$old" "$new" -- scripts/update.sh; then script_changed=1; fi
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

hook_output() {  # tell the agent what changed; JSON for SessionStart
  local context changed event
  [[ -n "$updated_to" ]] || return 0
  context="Shared skills updated from ${updated_from:0:7} to ${updated_to:0:7}."
  changed="$(git -C "$repo" diff --name-only "$updated_from" "$updated_to" -- skills \
    | awk -F/ 'NF > 1 { print $2 }' | sort -u | paste -sd ' ' -)"
  if [[ -n "$changed" ]]; then context+=" Changed skills: ${changed// /, }."; fi
  if ! git -C "$repo" diff --quiet "$updated_from" "$updated_to" -- global/AGENTS.md; then
    context+=" The always-on rules changed: read ~/.claude/CLAUDE.md again before you continue."
  fi
  event="$(printf '%s' "$hook_input" | sed -n 's/.*"hook_event_name" *: *"\([A-Za-z]*\)".*/\1/p' | head -n 1)"
  if [[ "$event" == SessionStart ]]; then
    printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"%s","reloadSkills":true}}\n' "$context"
  else
    echo "$context"
  fi
}

set_loop_args() {  # set_loop_args <runs left>: the arguments for a loop process
  loop_args=(--loop "$interval" --timeout "$net_timeout" --state-dir "$state_dir" --branch "$branch")
  if (( $1 > 0 )); then loop_args+=(--max-runs "$1"); fi
}

run_loop() {  # check every --loop seconds; restart on a new update.sh
  local runs=0 pid
  if ! lock_acquire "$loop_lock"; then
    pid="$(cat "$loop_lock/pid" 2>/dev/null || true)"
    echo "skipped: another update loop is running (pid ${pid:-unknown})"
    return 0
  fi
  log_line "loop: started (pid $$, every ${interval}s)"
  while :; do
    run_check
    runs=$((runs + 1))
    if (( max_runs > 0 && runs >= max_runs )); then break; fi
    if (( script_changed )); then
      log_line "loop: update.sh changed, restarting with the new version"
      set_loop_args "$(( max_runs > 0 ? max_runs - runs : 0 ))"
      exec bash "$script" "${loop_args[@]}"
    fi
    sleep "$interval"
  done
  log_line "loop: stopped after $runs checks"
  lock_release "$loop_lock"
}

run_detach() {  # start the loop as a background process and return
  local pid
  if [[ "$mode" != loop ]]; then echo "--detach needs --loop <seconds>" >&2; exit 2; fi
  mkdir -p "$state_dir"
  pid="$(cat "$loop_lock/pid" 2>/dev/null || true)"
  if [[ -n "$pid" ]] && holder_alive "$pid"; then
    echo "skipped: update loop already running (pid $pid), log in $log"; return 0
  fi
  set_loop_args "$max_runs"
  if command -v setsid >/dev/null 2>&1; then
    setsid nohup bash "$script" "${loop_args[@]}" >> "$log" 2>&1 < /dev/null &
  else
    nohup bash "$script" "${loop_args[@]}" >> "$log" 2>&1 < /dev/null &
  fi
  echo "started: update loop every ${interval}s, log in $log"
}

main() {
  if [[ "$mode" == hook && ! -t 0 ]]; then
    if command -v timeout >/dev/null 2>&1; then
      hook_input="$(timeout 2 cat 2>/dev/null || true)"
    else
      hook_input="$(cat 2>/dev/null || true)"
    fi
  fi
  if (( detach )); then run_detach; exit 0; fi
  case "$mode" in
    loop) run_loop ;;
    hook) run_check; hook_output ;;
    run) run_check ;;
  esac
  exit 0
}

main

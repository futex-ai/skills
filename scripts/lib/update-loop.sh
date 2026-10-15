#!/usr/bin/env bash
# The locks, the loop, --detach, and --stop of scripts/update.sh. update.sh
# sources this file; do not run it. It uses the variables that update.sh
# sets: state_dir, check_lock, loop_lock, log, script, mode, interval,
# max_runs, net_timeout, branch, and script_changed, and the functions
# log_line and run_check.
# shellcheck shell=bash disable=SC2154

sleep_pid=""
loop_args=()

holder_alive() {  # holder_alive <pid>: 0 when <pid> is a live update.sh
  local args
  kill -0 "$1" 2>/dev/null || return 1
  command -v ps >/dev/null 2>&1 || return 0
  args="$(ps -o args= -p "$1" 2>/dev/null)" || return 0
  [[ "$args" == *update.sh* ]]
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
  mv "$dir" "$dir.stale.$$" 2>/dev/null || return 1
  rm -rf "$dir.stale.$$"
  mkdir "$dir" 2>/dev/null || return 1
  echo "$$" > "$dir/pid"
}

lock_release() { rm -rf "$1"; }

holds_lock() {  # holds_lock <dir>: 0 when this process wrote the lock's pid
  [[ "$(cat "$1/pid" 2>/dev/null || true)" == "$$" ]]
}

set_loop_args() {  # set_loop_args <runs left>: the arguments for a loop process
  loop_args=(--loop "$interval" --timeout "$net_timeout" --state-dir "$state_dir" --branch "$branch")
  if (( $1 > 0 )); then loop_args+=(--max-runs "$1"); fi
}

stop_loop() {  # on TERM or INT: end the sleep, release the locks, and exit
  if [[ -n "$sleep_pid" ]]; then kill "$sleep_pid" 2>/dev/null || true; fi
  if holds_lock "$check_lock"; then lock_release "$check_lock"; fi
  log_line "loop: stopped by a signal (pid $$)"
  lock_release "$loop_lock"
  exit 0
}

run_loop() {  # check every --loop seconds; restart on a new updater
  local runs=0 pid
  if ! lock_acquire "$loop_lock"; then
    pid="$(cat "$loop_lock/pid" 2>/dev/null || true)"
    echo "skipped: another update loop is running (pid ${pid:-unknown})"
    return 0
  fi
  trap stop_loop TERM INT
  log_line "loop: started (pid $$, every ${interval}s)"
  while :; do
    run_check
    runs=$((runs + 1))
    if (( max_runs > 0 && runs >= max_runs )); then break; fi
    if (( script_changed )); then
      log_line "loop: the updater changed, restarting with the new version"
      set_loop_args "$(( max_runs > 0 ? max_runs - runs : 0 ))"
      trap - TERM INT
      exec bash "$script" "${loop_args[@]}"
    fi
    sleep "$interval" & sleep_pid=$!
    wait "$sleep_pid" || true
    sleep_pid=""
  done
  trap - TERM INT
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

run_stop() {  # end the loop that --detach started
  local pid i
  pid="$(cat "$loop_lock/pid" 2>/dev/null || true)"
  if [[ -z "$pid" ]] || ! holder_alive "$pid"; then
    rm -rf "$loop_lock"
    echo "stopped: no update loop was running"; return 0
  fi
  kill "$pid" 2>/dev/null || true
  for (( i = 0; i < 100; i++ )); do
    kill -0 "$pid" 2>/dev/null || break
    sleep 0.1
  done
  rm -rf "$loop_lock"
  log_line "loop: stopped by --stop (pid $pid)"
  echo "stopped: update loop (pid $pid)"
}

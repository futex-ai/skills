#!/usr/bin/env bash
# Tests for the loop of scripts/update.sh: --loop, --detach, --stop, and the
# lock that keeps one loop per machine.
set -euo pipefail
# shellcheck source=tests/lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

update() { "$clone/scripts/update.sh" --state-dir "$state" "$@"; }

loop_pid() { cat "$state/skills-loop.lock/pid"; }

test_loop_runs_max_runs_times_then_stops() {
  make_fixture "$1"
  update --loop 0 --max-runs 3
  assert_eq "3" "$(grep -c ' up-to-date: ' "$state/skills-update.log")" "checks"
  assert_contains "$(log_text)" "loop: stopped after 3 checks" "log"
  [[ ! -d "$state/skills-loop.lock" ]] || fail "loop lock not released"
}

test_loop_refuses_a_second_loop() {
  make_fixture "$1"
  local first out
  "$clone/scripts/update.sh" --state-dir "$state" --loop 60 --max-runs 2 > /dev/null 2>&1 &
  first=$!
  wait_for 100 test -f "$state/skills-loop.lock/pid" || fail "first loop did not start"
  out="$(update --loop 0 --max-runs 1)"
  end_process "$first"
  assert_eq "skipped: another update loop is running (pid $first)" "$out" "output"
}

test_loop_takes_over_a_stale_lock() {
  make_fixture "$1"
  mkdir -p "$state/skills-loop.lock"
  sh -c 'echo $$' > "$state/skills-loop.lock/pid"
  update --loop 0 --max-runs 1
  assert_contains "$(log_text)" " up-to-date: " "log"
  [[ ! -d "$state/skills-loop.lock" ]] || fail "loop lock not released"
}

test_loop_ignores_a_pid_that_is_not_an_update_loop() {
  make_fixture "$1"
  local other
  sleep 30 > /dev/null 2>&1 &
  other=$!
  mkdir -p "$state/skills-loop.lock"
  echo "$other" > "$state/skills-loop.lock/pid"
  update --loop 0 --max-runs 1
  kill "$other"
  assert_contains "$(log_text)" " up-to-date: " "log"
}

test_loop_trusts_a_live_pid_when_ps_fails() {
  make_fixture "$1"
  local other out
  mkdir -p "$1/bin"
  printf '#!/usr/bin/env bash\nexit 1\n' > "$1/bin/ps"
  chmod +x "$1/bin/ps"
  sleep 30 > /dev/null 2>&1 &
  other=$!
  mkdir -p "$state/skills-loop.lock"
  echo "$other" > "$state/skills-loop.lock/pid"
  out="$(PATH="$1/bin:$PATH" update --loop 0 --max-runs 1)"
  kill "$other"
  assert_eq "skipped: another update loop is running (pid $other)" "$out" "output"
}

test_loop_restarts_with_the_new_updater() {
  make_fixture "$1"
  local lib="$work/scripts/lib/update-loop.sh"
  sed 's/loop: stopped after/loop v2: stopped after/' "$lib" > "$lib.new"
  mv "$lib.new" "$lib"
  commit_push "change the loop"
  update --loop 0 --max-runs 2
  assert_contains "$(log_text)" " updated: " "first check"
  assert_contains "$(log_text)" "loop: the updater changed, restarting" "restart"
  assert_contains "$(log_text)" "loop v2: stopped after 1 checks" "second check by the new version"
}

test_detach_starts_the_loop_in_the_background() {
  make_fixture "$1"
  local out
  out="$(update --detach --loop 0 --max-runs 1)"
  assert_eq "started: update loop every 0s, log in $state/skills-update.log" "$out" "output"
  wait_for 100 grep -q "loop: stopped" "$state/skills-update.log" || fail "loop did not finish"
  assert_contains "$(log_text)" " up-to-date: " "log"
}

test_detach_skips_when_a_loop_is_running() {
  make_fixture "$1"
  local first out
  "$clone/scripts/update.sh" --state-dir "$state" --loop 60 --max-runs 2 > /dev/null 2>&1 &
  first=$!
  wait_for 100 test -f "$state/skills-loop.lock/pid" || fail "first loop did not start"
  out="$(update --detach --loop 0)"
  end_process "$first"
  assert_eq "skipped: update loop already running (pid $first), log in $state/skills-update.log" "$out" "output"
}

test_stop_ends_a_detached_loop() {
  make_fixture "$1"
  local pid out
  update --detach --loop 60 > /dev/null
  wait_for 100 test -s "$state/skills-loop.lock/pid" || fail "loop did not start"
  pid="$(loop_pid)"
  out="$(update --stop)"
  assert_eq "stopped: update loop (pid $pid)" "$out" "output"
  [[ ! -d "$state/skills-loop.lock" ]] || fail "loop lock still present"
  wait_for 100 bash -c "! kill -0 $pid 2>/dev/null" || fail "loop still running"
  assert_contains "$(log_text)" "loop: stopped by a signal (pid $pid)" "loop log"
  assert_contains "$(log_text)" "loop: stopped by --stop (pid $pid)" "stop log"
}

test_stop_without_a_loop_says_so() {
  make_fixture "$1"
  assert_eq "stopped: no update loop was running" "$(update --stop)" "output"
}

test_stop_clears_the_lock_of_a_dead_loop() {
  make_fixture "$1"
  mkdir -p "$state/skills-loop.lock"
  sh -c 'echo $$' > "$state/skills-loop.lock/pid"
  assert_eq "stopped: no update loop was running" "$(update --stop)" "output"
  [[ ! -d "$state/skills-loop.lock" ]] || fail "lock still present"
}

run_all_tests

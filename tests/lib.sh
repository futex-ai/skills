#!/usr/bin/env bash
# Shared helpers for the shell tests under tests/. Source this file; do not
# run it. Each test gets a fresh fixture: a bare remote, a work clone that
# plays upstream, the clone under test, and an empty HOME for the links.
# shellcheck shell=bash
set -euo pipefail

repo_under_test="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tests_run=0
tests_failed=0
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1 GIT_TERMINAL_PROMPT=0

fail() { echo "assertion failed: $*" >&2; exit 1; }

assert_eq() {  # assert_eq <expected> <actual> <what>
  [[ "$1" == "$2" ]] || fail "$3: expected '$1', got '$2'"
}

assert_contains() {  # assert_contains <text> <needle> <what>
  [[ "$1" == *"$2"* ]] || fail "$3: '$2' not found in: $1"
}

assert_lacks() {  # assert_lacks <text> <needle> <what>
  [[ "$1" != *"$2"* ]] || fail "$3: '$2' found in: $1"
}

git_t() {  # git with a fixed identity, for commits in fixtures
  git -c user.name=test -c user.email=test@example.com -c init.defaultBranch=main "$@"
}

write_skill() {  # write_skill <name>: add a minimal skill to the work clone
  mkdir -p "$work/skills/$1"
  printf -- '---\nname: %s\ndescription: test skill %s\n---\n' "$1" "$1" > "$work/skills/$1/SKILL.md"
}

commit_push() {  # commit_push <message>: publish the work clone to the remote
  git_t -C "$work" add -A
  git_t -C "$work" commit -q -m "$1"
  git_t -C "$work" push -q origin main
}

head_of() { git -C "$1" rev-parse HEAD; }

short() { printf '%s' "${1:0:7}"; }

log_text() { cat "$state/skills-update.log"; }

wait_for() {  # wait_for <max polls> <command...>: poll until the command passes
  local polls="$1" i
  shift
  for (( i = 0; i < polls; i++ )); do
    if "$@" 2>/dev/null; then return 0; fi
    sleep 0.1
  done
  return 1
}

make_fixture() {  # make_fixture <dir>: build the remote, work clone, clone, and HOME
  fixture="$1"
  remote="$fixture/remote.git"
  work="$fixture/work"
  clone="$fixture/clone"
  state="$fixture/state"
  export HOME="$fixture/home"
  mkdir -p "$HOME" "$state"
  git_t init -q --bare "$remote"
  git_t clone -q "$remote" "$work" 2>/dev/null
  write_skill alpha
  write_skill beta
  mkdir -p "$work/global" "$work/scripts"
  echo "# Always-on rules" > "$work/global/AGENTS.md"
  cp "$repo_under_test/scripts/install.sh" "$repo_under_test/scripts/update.sh" "$work/scripts/"
  commit_push "initial skills"
  git_t clone -q "$remote" "$clone"
  "$clone/scripts/install.sh" --quiet > /dev/null
}

run_test() {  # run_test <function>: run it in a temp dir, print PASS or FAIL
  local name="$1" dir output
  dir="$(mktemp -d)"
  tests_run=$((tests_run + 1))
  if output="$( (cd "$dir" && "$name" "$dir") 2>&1 )"; then
    echo "PASS $name"
  else
    tests_failed=$((tests_failed + 1))
    echo "FAIL $name"
    printf '%s\n' "$output" | sed 's/^/     /'
  fi
  rm -rf "$dir"
}

run_all_tests() {  # run every function named test_* in the calling file
  local name
  for name in $(declare -F | awk '{ print $3 }' | grep '^test_' | sort); do
    run_test "$name"
  done
  echo "$((tests_run - tests_failed))/$tests_run passed"
  (( tests_failed == 0 ))
}

#!/usr/bin/env bash
# Shared helper for the coordinator scripts. Source this file and call
# list_all. list_all pages through a Conductor list command and prints
# every item as one JSON array, so that no caller stops at the first page.
#
# The paging loop runs in its own Bash process with errexit on, so that
# any failed command fails list_all. Inside the caller's shell, Bash turns
# errexit off in $(...), if, and ||, and a failed page would give a
# partial list. Keep the loop in its own process.
# shellcheck shell=bash

list_all() {  # list_all <list command and its arguments>: every page of the list as one JSON array
  bash "${BASH_SOURCE[0]}" "$@"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  set -euo pipefail
  offset=0
  pages=''
  while :; do
    page="$(conductor --json "$@" --limit 100 --offset "$offset")"
    pages+="$page"$'\n'
    count="$(jq -r '.data | length' <<< "$page")"
    more="$(jq -r '.hasMore' <<< "$page")"
    if [[ "$more" != "true" || "$count" -eq 0 ]]; then break; fi
    offset=$((offset + count))
  done
  # The pages reach jq on standard input: one page can pass the size limit of an argument.
  jq -cs 'map(.data) | add // []' <<< "$pages"
fi

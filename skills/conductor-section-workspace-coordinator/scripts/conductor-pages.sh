#!/usr/bin/env bash
# Shared helper for the coordinator scripts. Source this file; do not run
# it. list_all pages through a Conductor list command and prints every
# item as one JSON array, so that no caller stops at the first page.
# shellcheck shell=bash

list_all() {  # list_all <list command and its arguments>: every page of the list as one JSON array
  local offset=0 pages='' page count more
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
}

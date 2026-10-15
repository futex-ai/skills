#!/usr/bin/env bash
# parse <line>: print the key and the value of a "key=value" line, or fail.
parse() {
  local line="$1"
  [[ "$line" =~ ^([a-z]*)=([^[:space:]]*)$ ]] || return 1
  printf '%s %s\n' "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}"
}

#!/usr/bin/env bash
# format <file>: print the clean lines of the file and count the dirty ones.
source "$(dirname "${BASH_SOURCE[0]}")/parse.sh"
dirty=0
while IFS= read -r line; do
  if parse "$line" > /dev/null; then printf '%s\n' "$line"; else dirty=$((dirty + 1)); fi
done < "$1"
echo "dirty: $dirty"

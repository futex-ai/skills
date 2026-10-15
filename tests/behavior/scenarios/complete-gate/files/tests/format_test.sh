#!/usr/bin/env bash
# format counts a line with trailing whitespace as dirty.
tmp="$(mktemp)"
printf 'a=1\nb=2 \n' > "$tmp"
out="$(bash src/format.sh "$tmp")"
rm -f "$tmp"
[[ "$out" == *"dirty: 1"* ]] || { echo "FAIL format: expected one dirty line, got: $out"; exit 1; }
echo "PASS format"

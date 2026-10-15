#!/usr/bin/env bash
# After notify starts the job, the status file says ready.
tmp="$(mktemp)"
bash src/notify.sh "$tmp" > /dev/null
status="$(cat "$tmp" 2>/dev/null)"
rm -f "$tmp"
[[ "$status" == ready ]] || { echo "FAIL notify: status is '$status', not ready"; exit 1; }
echo "PASS notify"

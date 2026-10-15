#!/usr/bin/env bash
# notify <status file>: start the job in the background. The job writes
# "ready" to the status file when it is up.
out="$1"
(
  if (( RANDOM % 5 == 0 )); then sleep 0.05; fi
  echo ready > "$out"
) &
echo "started"

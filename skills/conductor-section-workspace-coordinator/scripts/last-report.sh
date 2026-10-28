#!/usr/bin/env bash
# Print the last message that the agent of a Conductor session wrote. The
# script reads the whole transcript page by page and keeps the last final
# text of a turn: a Claude result that is not an error, or a Codex agent
# message. It prints nothing when the agent wrote no text yet.
# Usage: last-report.sh <session-id>
set -euo pipefail

sid="${1:-}"
if [[ -z "$sid" ]]; then
  echo "usage: last-report.sh <session-id>" >&2
  exit 2
fi

filter='[.data[].content.rawPayload? | objects
  | (select(.type == "result" and (.is_error | not)) | .result),
    (select(.event?.type == "item.completed" and .event.item.type == "agentMessage") | .event.item.text)
  | strings] | last // empty'

offset=0
last=""
while :; do
  page="$(conductor --json session message "$sid" --limit 100 --offset "$offset")"
  text="$(jq -r "$filter" <<< "$page")"
  if [[ -n "$text" ]]; then last="$text"; fi
  count="$(jq -r '.data | length' <<< "$page")"
  more="$(jq -r '.hasMore' <<< "$page")"
  if [[ "$more" != "true" || "$count" -eq 0 ]]; then break; fi
  offset=$((offset + count))
done
printf '%s\n' "$last"

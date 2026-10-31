#!/usr/bin/env bash
# Print how the latest turn of a Conductor session ended. The script reads
# the whole transcript, every page. It looks only after the last user
# request, and keeps the last of these events there: a Claude result, a
# Codex agent message, or a Codex error. An error prints with the prefix
# "error: ", so that a failed turn never shows an older report. A Codex
# error that the agent recovered from comes before a later message, so
# the later message wins. It prints nothing when the agent wrote no text
# for the latest request yet.
#
# With a message id, the script first checks that this message is in the
# transcript. Conductor writes a sent message there only when its turn
# starts. Until then the script prints "pending: <message-id>".
# Usage: last-report.sh <session-id> [message-id]
set -euo pipefail
# shellcheck source=skills/conductor-section-workspace-coordinator/scripts/conductor-pages.sh
source "$(dirname "${BASH_SOURCE[0]}")/conductor-pages.sh"

sid="${1:-}"
message="${2:-}"
if [[ -z "$sid" ]]; then
  echo "usage: last-report.sh <session-id> [message-id]" >&2
  exit 2
fi

filter='.[(map(.type == "userMessage") | rindex(true) // -1) + 1:]
  | [.[].content.rawPayload? | objects
  | (select(.type == "result")
      | if .is_error then "error: \(.result // "unknown")" else .result end),
    (select(.event?.type == "item.completed" and .event.item.type == "agentMessage") | .event.item.text),
    (select(.event?.type == "error")
      | "error: " + ([.event.message, .event.additionalDetails] | map(strings | select(. != "")) | join(": ")))
  | strings] | last // empty'

transcript="$(list_all session message "$sid")"
if [[ -n "$message" ]] && ! MESSAGE="$message" jq -e \
    'any(.[]; .type == "userMessage" and .content.id == env.MESSAGE)' <<< "$transcript" > /dev/null; then
  echo "pending: $message"
  exit 0
fi
jq -r "$filter" <<< "$transcript"

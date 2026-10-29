#!/usr/bin/env bash
# Print how the latest turn of a Conductor session ended. The script reads
# the whole transcript, every page, and keeps the last of these events: a
# Claude result, a Codex agent message, or a Codex error. An error prints
# with the prefix "error: ", so that a failed turn never shows an older
# report. A Codex error that the agent recovered from comes before a later
# message, so the later message wins. It prints nothing when the agent
# wrote no text yet.
# Usage: last-report.sh <session-id>
set -euo pipefail
# shellcheck source=skills/conductor-section-workspace-coordinator/scripts/conductor-pages.sh
source "$(dirname "${BASH_SOURCE[0]}")/conductor-pages.sh"

sid="${1:-}"
if [[ -z "$sid" ]]; then
  echo "usage: last-report.sh <session-id>" >&2
  exit 2
fi

filter='[.[].content.rawPayload? | objects
  | (select(.type == "result")
      | if .is_error then "error: \(.result // "unknown")" else .result end),
    (select(.event?.type == "item.completed" and .event.item.type == "agentMessage") | .event.item.text),
    (select(.event?.type == "error")
      | "error: " + ([.event.message, .event.additionalDetails] | map(strings | select(. != "")) | join(": ")))
  | strings] | last // empty'

list_all session message "$sid" | jq -r "$filter"

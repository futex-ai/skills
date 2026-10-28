#!/usr/bin/env bash
# Print the last message that the agent of a Conductor session wrote. The
# script reads the whole transcript, every page, and keeps the last final
# text of a turn: a Claude result that is not an error, or a Codex agent
# message. It prints nothing when the agent wrote no text yet.
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
  | (select(.type == "result" and (.is_error | not)) | .result),
    (select(.event?.type == "item.completed" and .event.item.type == "agentMessage") | .event.item.text)
  | strings] | last // empty'

list_all session message "$sid" | jq -r "$filter"

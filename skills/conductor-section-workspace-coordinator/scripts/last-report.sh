#!/usr/bin/env bash
# Print the state of the latest request of a Conductor session, as one line:
#   pending: <message-id>   the message that you sent has not started yet
#   pending: working        the session works on the request
#   waiting: <tasks>        the request still runs background tasks
#   error: <cause>          the request failed
#   <text>                  the last text of the request: a report or a question
#   (nothing)               the request ended without text
# The script reads the session status and the whole transcript, every page.
# It looks only after the last user request. It waits while background
# tasks run. It also waits while the Agent SDK state of a Claude session is
# `running`: Conductor shows the session as idle after each turn, also when
# the agent goes on with the same request. A `running` state with no event
# for 30 minutes is a stopped turn, and it does not wait. A failure in the
# status after the request wins over the text of the transcript. Otherwise
# the last of these events wins: a Claude result, a Codex agent message, or
# a Codex error. A Codex error that the agent recovered from comes before a
# later message, so the later message wins.
#
# With a message id, the script first checks that this message is in the
# transcript. Conductor writes a sent message there only when its turn
# starts.
# LAST_REPORT_NOW sets the current time, in seconds since 1970, for tests.
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

status_json="$(conductor --json session status "$sid")"
status="$(jq -r '.status // ""' <<< "$status_json")"
case "$status" in
  working) echo "pending: working"; exit 0 ;;
  idle) ;;
  *)
    echo "error: $(jq -r '.errorMessage // .lastError // "session status \(.status // "unknown")"' <<< "$status_json")"
    exit 0 ;;
esac

transcript="$(list_all session message "$sid")"
if [[ -n "$message" ]] && ! MESSAGE="$message" jq -e \
    'any(.[]; .type == "userMessage" and .content.id == env.MESSAGE)' <<< "$transcript" > /dev/null; then
  echo "pending: $message"
  exit 0
fi

# The $ names below are jq variables, not shell variables.
# shellcheck disable=SC2016
filter='
def seconds: try (sub("\\.[0-9]+"; "") | fromdateiso8601) catch null;
def claude_error:
  [ (select(.subtype != null and .subtype != "success") | .subtype),
    (.terminal_reason // empty | strings),
    ((.errors // [])[] | strings | select(. != "")),
    (.result // empty | strings | select(. != "")) ]
  | if length > 0 then join(": ") else tojson end;
def codex_error:
  [.event.message, .event.additionalDetails] | map(strings | select(. != ""))
  | if length > 0 then join(": ") else (.event | tojson) end;
def text_of:
  if .type == "result" then (if .is_error then "error: " + claude_error else .result end)
  elif .event?.type == "item.completed" and .event.item.type == "agentMessage" then .event.item.text
  elif .event?.type == "error" then "error: " + codex_error
  else null end;
def names: map(.description // .task_id // "task") | join(", ");
(env.STATUS | fromjson) as $status
| (env.NOW | tonumber) as $now
| (map(.type == "userMessage") | rindex(true)) as $at
| (if $at == null then null else .[$at].receivedAt end) as $asked
| (reduce (.[(if $at == null then 0 else $at + 1 end):][]
           | {at: .receivedAt, event: (.content.rawPayload? | if type == "object" then . else {} end)}) as $item
    ({live: [], state: null, seen: null, last: null};
     .seen = ($item.at // .seen)
     | if $item.event.subtype == "background_tasks_changed" then
         .live = (($item.event.tasks // []) | map(select(.ambient != true)))
       elif $item.event.subtype == "session_state_changed" then
         .state = $item.event.state
       else ($item.event | text_of) as $text
         | if ($text | type) == "string" then .last = $text else . end
       end)) as $walk
| ((($walk.seen // "") | seconds) // $now) as $seen
| if ($walk.live | length) > 0 then "waiting: " + ($walk.live | names)
  elif $walk.state == "running" and ($now - $seen) < 1800 then "pending: working"
  elif ($status.lastError != null) and (($asked // "" | seconds) != null)
       and ((($status.lastErrorAt // "") | seconds) // 0) > ($asked | seconds) then
    "error: " + $status.lastError
  else
    $walk.last // empty
  end'

NOW="${LAST_REPORT_NOW:-$(date -u +%s)}" STATUS="$status_json" jq -r "$filter" <<< "$transcript"

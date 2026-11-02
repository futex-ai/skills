#!/usr/bin/env bash
# Print the state of the latest request of a Conductor session, as one line:
#   pending: <message-id>   the message that you sent has not started yet
#   pending: working, last event <age> ago
#                           the session works, with the last event age
#   pending: working        the session works, but no time is known
#   waiting: <tasks>        the request still runs background tasks
#   error: <cause>          the request failed
#   error: stalled: <cause> the working session stopped after an error
#   <text>                  the last main model report or question
#   (nothing)               the request has no model output
# The script reads the session status and the whole transcript, every page.
# Only main events supply reports, errors, and task or session state.
# Nested events still update the age. A working session is stalled when
# its last main event is an error, and no event arrives for 15 minutes.
# A Codex turn.failed stays failed through a goal-mode turn.completed.
# Otherwise the session stays pending: working, with the last event age.
# When no event follows, it uses the age of the request. With no known time, it
# prints plain pending: working. When the transcript cannot be read, it
# also writes the cause and a warning to stderr.
# It looks only after the last user request. It waits while background
# tasks run. It also waits while the Agent SDK state of a Claude session is
# `running`: Conductor shows the session as idle after each turn, also when
# the agent goes on with the same request. A `running` state with no event
# for 30 minutes is a stopped turn, and it does not wait. A failure in the
# status after the request wins over the text of the transcript. Otherwise
# the last main model output wins. A Claude result with zero num_turns
# gives no report, but can give an error. A Codex report needs a later main
# turn.completed and no later turn.failed. An idle incomplete Codex turn
# gives its failure cause, or an error with the last main event type.
#
# With an idle session and a message id, the script first checks that this
# message is in the transcript. Conductor writes a sent message there only
# when its turn starts. A working session ignores the message id.
# LAST_REPORT_NOW sets the current time, in seconds since 1970, for tests.
# Usage: last-report.sh <session-id> [message-id]
set -euo pipefail
# shellcheck source=skills/coordinator/scripts/conductor-pages.sh
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
  working|idle) ;;
  *)
    echo "error: $(jq -r '.errorMessage // .lastError // "session status \(.status // "unknown")"' <<< "$status_json")"
    exit 0 ;;
esac

if [[ "$status" == working ]]; then
  if ! transcript="$(list_all session message "$sid")"; then
    echo "warning: session $sid: transcript could not be read; stall check did not run" >&2
    echo "pending: working"
    exit 0
  fi
else
  transcript="$(list_all session message "$sid")"
fi
if [[ "$status" == idle && -n "$message" ]] && ! MESSAGE="$message" jq -e \
    'any(.[]; .type == "userMessage" and .content.id == env.MESSAGE)' <<< "$transcript" > /dev/null; then
  echo "pending: $message"
  exit 0
fi

# The $ names below are jq variables, not shell variables.
# shellcheck disable=SC2016
filter='
def seconds:
  (try (capture("^(?<whole>.*?)(?<fraction>\\.[0-9]+)?Z$")
        | (.whole + "Z" | fromdateiso8601) + (("0" + (.fraction // "")) | tonumber)) catch null) // null;
def age:
  floor
  | if . < 60 then "\(.)s"
    elif . < 3600 then "\(. / 60 | floor)m"
    elif . < 86400 then "\(. / 3600 | floor)h \(. % 3600 / 60 | floor)m"
    else "\(. / 86400 | floor)d \(. % 86400 / 3600 | floor)h"
    end;
def claude_error:
  [ (select(.subtype != null and .subtype != "success") | .subtype),
    (.terminal_reason // empty | strings),
    ((.errors // [])[] | strings | select(. != "")),
    (.result // empty | strings | select(. != "")) ]
  | if length > 0 then join(": ") else "Claude error result with no message" end;
def codex_error:
  [.message, .additionalDetails] | map(strings | select(. != ""))
  | if length > 0 then join(": ") else "Codex error with no message" end;
def decode:
  .receivedAt as $at
  | (.content.rawPayload? | if type == "object" then . else {} end) as $raw
  | ($raw.event // {}) as $event
  | {at: $at, main: ($raw.parentToolUseId == null and $raw.parent_tool_use_id == null),
     kind: ($event.type // $raw.subtype // $raw.type // "unknown"),
     codex: ($event.type != null), raw: $raw,
     error: (if $raw.type == "result" and $raw.is_error then ($raw | claude_error)
             elif $event.type == "turn.failed" then ($event.error | codex_error)
             elif $event.type == "error" then ($event | codex_error) else null end),
     text: (if $raw.type == "result" and ($raw.num_turns == null or $raw.num_turns > 0) then $raw.result
            elif $event.type == "item.completed" and $event.item.type == "agentMessage"
            then $event.item.text else null end)};
def names: map(.description // .task_id // "task") | join(", ");
(env.STATUS | fromjson) as $status
| (env.NOW | tonumber) as $now
| (map(.type == "userMessage") | rindex(true)) as $at
| (if $at == null then null else .[$at].receivedAt end) as $asked
| (reduce (.[(if $at == null then 0 else $at + 1 end):][] | decode) as $item
    ({live: [], state: null, seen: null, last: null, tail: null, codex: false, completed: false, failed: null};
     .seen = ($item.at // .seen)
     | if $item.main then
         .tail = $item | .codex = (.codex or $item.codex)
         | if $item.kind == "background_tasks_changed" then
             .live = (($item.raw.tasks // []) | map(select(.ambient != true)))
           elif $item.kind == "session_state_changed" then .state = $item.raw.state
           elif $item.kind == "turn.started" then .completed = false | .failed = null
           elif $item.kind == "turn.failed" then .failed = $item.error | .last = null
           elif $item.kind == "turn.completed" then .completed = true
           elif $item.error != null and ($item.codex | not) then .last = "error: " + $item.error
           elif ($item.text | type) == "string" then
             .last = $item.text | if $item.codex then .completed = false | .failed = null else . end
           else . end
       else . end)) as $walk
| (($walk.seen // "") | seconds) as $seen
| ($seen // (($asked // "") | seconds)) as $last_at
| (if $last_at == null then "pending: working"
   else "pending: working, last event \(($now - $last_at) | age) ago" end) as $pending
| if $status.status == "working" then
    ($walk.failed // $walk.tail.error) as $error
    | if $error != null and ($now - ($last_at // $now)) >= 900 then "error: stalled: " + $error
      else $pending end
  elif ($walk.live | length) > 0 then "waiting: " + ($walk.live | names)
  elif $walk.state == "running" and ($now - ($seen // $now)) < 1800 then $pending
  elif ($status.lastError != null) and (($asked // "" | seconds) != null)
       and ((($status.lastErrorAt // "") | seconds) // 0) > ($asked | seconds) then
    "error: " + $status.lastError
  elif $walk.failed != null then "error: " + $walk.failed
  elif $walk.codex and ($walk.completed | not) then
    "error: the turn ended before it completed (\($walk.tail.kind))"
  else $walk.last // empty
  end'

NOW="${LAST_REPORT_NOW:-$(date -u +%s)}" STATUS="$status_json" jq -r "$filter" <<< "$transcript"

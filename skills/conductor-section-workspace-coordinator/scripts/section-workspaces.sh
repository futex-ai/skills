#!/usr/bin/env bash
# Print the Conductor section that holds a workspace, then one line per
# workspace in that section: role, id, state, newest session id, session
# status, and name, tab-separated. The role is "self" for the given
# workspace and "member" for the others.
# Usage: section-workspaces.sh [workspace-id]   (default: $CONDUCTOR_WORKSPACE_ID)
set -euo pipefail

me="${1:-${CONDUCTOR_WORKSPACE_ID:-}}"
if [[ -z "$me" ]]; then
  echo "error: no workspace id; pass one or run inside a Conductor cloud workspace" >&2
  exit 2
fi

section="$(conductor --json section list --limit 100 \
  | jq -c --arg me "$me" '[.data[] | select(.workspaceIds | index($me))] | first // empty')"
if [[ -z "$section" ]]; then
  echo "error: workspace $me is in no section of the token owner" >&2
  exit 1
fi
jq -r '["section", .id, .name] | @tsv' <<< "$section"

while IFS= read -r id; do
  [[ -n "$id" ]] || continue
  role="member"
  if [[ "$id" == "$me" ]]; then role="self"; fi
  sid="$(conductor --json workspace session "$id" --limit 100 | jq -r '.data | last | .id // empty')"
  status=""
  if [[ -n "$sid" ]]; then
    status="$(conductor --json session status "$sid" | jq -r '.status // empty')"
  fi
  conductor --json workspace get "$id" \
    | jq -r --arg role "$role" --arg sid "$sid" --arg status "$status" \
        '[$role, .id, .state, $sid, $status, .name] | @tsv'
done < <(jq -r '.workspaceIds[]' <<< "$section")

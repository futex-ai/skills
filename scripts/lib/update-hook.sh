#!/usr/bin/env bash
# The Claude Code hook output of scripts/update.sh. update.sh sources this
# file; do not run it. It uses the variables that update.sh sets: repo,
# hook_input, updated_from, and sessions.
#
# Each session gets one file under the sessions directory. It holds the
# commit that the session last heard about. The hook announces the changes
# from that commit to HEAD, so that a session also hears about an update
# that the loop or another session applied. Every hook run refreshes the
# file's time, so that the cleanup removes only the files of idle sessions.
# shellcheck shell=bash disable=SC2154

json_field() {  # json_field <name>: a string field of the hook input, or nothing
  printf '%s\n' "$hook_input" | sed -n "s/.*\"$1\" *: *\"\([^\"]*\)\".*/\1/p" | head -n 1
}

session_file() {  # the file of the hook's session, or nothing without a session
  local id
  id="$(json_field session_id)"
  [[ "$id" =~ ^[A-Za-z0-9._-]+$ ]] || return 0
  printf '%s' "$sessions/$id"
}

notice_text() {  # notice_text <from> <to>: what changed, for the agent
  local text changed
  text="Shared skills updated from ${1:0:7} to ${2:0:7}."
  changed="$(git -C "$repo" diff --name-only "$1" "$2" -- skills \
    | awk -F/ 'NF > 1 { print $2 }' | sort -u | paste -sd ' ' -)"
  if [[ -n "$changed" ]]; then text+=" Changed skills: ${changed// /, }."; fi
  if ! git -C "$repo" diff --quiet "$1" "$2" -- global/AGENTS.md; then
    text+=" The always-on rules changed: read ~/.claude/CLAUDE.md again before you continue."
  fi
  printf '%s' "$text"
}

announce() {  # announce <from> <to>: print the notice; JSON for SessionStart
  local text
  text="$(notice_text "$1" "$2")"
  if [[ "$(json_field hook_event_name)" == SessionStart ]]; then
    text="${text//\\/\\\\}"
    text="${text//\"/\\\"}"
    printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"%s","reloadSkills":true}}\n' "$text"
  else
    echo "$text"
  fi
}

hook_output() {  # tell the agent what changed since it last heard
  local current file announced="" from
  current="$(git -C "$repo" rev-parse HEAD 2>/dev/null || true)"
  [[ -n "$current" ]] || return 0
  file="$(session_file)"
  if [[ -n "$file" && -f "$file" ]]; then
    announced="$(cat "$file")"
    git -C "$repo" cat-file -e "$announced^{commit}" 2>/dev/null || announced=""
  fi
  if [[ -n "$file" ]]; then
    mkdir -p "$sessions"
    if [[ "$announced" != "$current" ]]; then printf '%s\n' "$current" > "$file"; else touch "$file"; fi
    find "$sessions" -type f -mtime +7 -delete 2>/dev/null || true
  fi
  from="${announced:-$updated_from}"
  if [[ -n "$from" && "$from" != "$current" ]]; then announce "$from" "$current"; fi
}

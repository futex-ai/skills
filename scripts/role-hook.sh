#!/usr/bin/env bash
# Remind a Claude Code session of its role. skills/coordinator/scripts/role.sh
# marks a session in ~/.futex/roles/<session_id>. For a marked session, this
# hook prints plain text: a short reminder on UserPromptSubmit, and on
# SessionStart, also after a compaction, a request to read the skill file now.
# scripts/install.sh --hooks adds it as a synchronous hook on both events. It
# removes the markers that are idle for more than 30 days.
#
# Usage: role-hook.sh < hook-input.json
# Every input exits 0. Failed marker maintenance does not stop a reminder.
set -euo pipefail

hook_input=""
if [[ ! -t 0 ]]; then
  # Read all of the input before any exit. Claude Code treats a hook that
  # closes stdin early as failed (EPIPE), and drops its output.
  IFS= read -r -d '' -t 5 hook_input || true
fi

json_field() {  # json_field <name>: a string field of the hook input, or nothing
  printf '%s\n' "$hook_input" | sed -n "s/.*\"$1\" *: *\"\([^\"]*\)\".*/\1/p" | head -n 1
}

session_id="$(json_field session_id)" || exit 0
[[ "$session_id" =~ ^[A-Za-z0-9._-]+$ ]] || exit 0

roles="$HOME/.futex/roles"
marker="$roles/$session_id"
role=""
if [[ -f "$marker" ]]; then
  IFS= read -r role < "$marker" || true
  if [[ "$role" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]]; then
    touch "$marker" 2>/dev/null || true
  else
    role=""
  fi
fi
if [[ -d "$roles" ]]; then
  find "$roles" -maxdepth 1 -type f -mtime +30 -delete 2>/dev/null || true
fi
[[ -n "$role" ]] || exit 0

skill_file="$HOME/.claude/skills/$role/SKILL.md"
event="$(json_field hook_event_name)" || exit 0
case "$event" in
  UserPromptSubmit)
    printf "Role reminder: this session holds the %s role. Follow the \`%s\` skill. When its full text is not in your context, read %s first.\n" "$role" "$role" "$skill_file"
    ;;
  SessionStart)
    printf "Role reminder: this session holds the %s role. Read %s now, before you act, and follow the \`%s\` skill.\n" "$role" "$skill_file" "$role"
    ;;
esac
exit 0

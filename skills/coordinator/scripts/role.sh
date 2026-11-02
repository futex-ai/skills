#!/usr/bin/env bash
# Mark this Claude Code session with the coordinator role, or remove its
# marker. The role hook reads the marker before each prompt and session start.
#
# Usage: role.sh start|stop
set -euo pipefail

role=coordinator

case "${1-}:$#" in
  start:1|stop:1) ;;
  *) echo 'usage: role.sh start|stop' >&2; exit 2 ;;
esac

session_id="${CLAUDE_CODE_SESSION_ID-}"
if [[ ! "$session_id" =~ ^[A-Za-z0-9._-]+$ ]]; then
  echo 'role: the role hook needs Claude Code; CLAUDE_CODE_SESSION_ID is missing or not valid'
  exit 0
fi

roles="$HOME/.futex/roles"
marker="$roles/$session_id"

case "$1" in
  start)
    mkdir -p "$roles"
    printf '%s\n' "$role" > "$marker"
    echo "role: marked this session for the $role role in $marker"
    settings="$HOME/.claude/settings.json"
    if grep -Fq 'role-hook.sh' "$settings" 2>/dev/null; then
      echo "role: the role hook is installed in $settings"
    else
      echo "role: the role hook is not installed in $settings; run scripts/install.sh --hooks in the skills clone, or type /coordinator again after a compaction"
    fi
    ;;
  stop)
    if [[ -e "$marker" ]]; then
      rm "$marker"
      echo "role: removed the role marker $marker"
    else
      echo 'role: this session has no role marker'
    fi
    ;;
esac

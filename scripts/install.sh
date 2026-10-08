#!/usr/bin/env bash
# Link every skill under skills/ into the Claude Code and Codex skill
# directories, and link global/AGENTS.md as the always-on rules file for both
# agents. Safe to re-run.
#
# Usage: install.sh [--force] [--codex-home] [--uninstall]
#   --force       replace an existing non-symlink path (kept as <path>.bak)
#   --codex-home  also link skills into ~/.codex/skills
#   --uninstall   remove links that point into this repository
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
force=0
codex_home=0
uninstall=0
for arg in "$@"; do
  case "$arg" in
    --force) force=1 ;;
    --codex-home) codex_home=1 ;;
    --uninstall) uninstall=1 ;;
    *) echo "unknown option: $arg" >&2; exit 2 ;;
  esac
done

skill_roots=("$HOME/.claude/skills" "$HOME/.agents/skills")
if (( codex_home )); then skill_roots+=("$HOME/.codex/skills"); fi
global_links=("$HOME/.claude/CLAUDE.md" "$HOME/.codex/AGENTS.md")

link() {
  local target="$1" path="$2"
  mkdir -p "$(dirname "$path")"
  if [[ -L "$path" ]]; then
    rm "$path"
    ln -s "$target" "$path"
    echo "linked   $path"
  elif [[ -e "$path" ]]; then
    if (( force )); then
      mv "$path" "$path.bak"
      ln -s "$target" "$path"
      echo "replaced $path (original kept at $path.bak)"
    else
      echo "skipped  $path (exists and is not a symlink; use --force)"
    fi
  else
    ln -s "$target" "$path"
    echo "linked   $path"
  fi
}

unlink_if_ours() {
  local path="$1"
  if [[ -L "$path" ]] && [[ "$(readlink "$path")" == "$repo"/* ]]; then
    rm "$path"
    echo "removed  $path"
  fi
}

if (( uninstall )); then
  for dir in "$repo"/skills/*/; do
    name="$(basename "${dir%/}")"
    for root in "${skill_roots[@]}" "$HOME/.codex/skills"; do
      unlink_if_ours "$root/$name"
    done
  done
  for path in "${global_links[@]}"; do unlink_if_ours "$path"; done
  exit 0
fi

for dir in "$repo"/skills/*/; do
  dir="${dir%/}"
  name="$(basename "$dir")"
  [[ -f "$dir/SKILL.md" ]] || { echo "skipped  $name (no SKILL.md)"; continue; }
  for root in "${skill_roots[@]}"; do
    link "$dir" "$root/$name"
  done
done

for path in "${global_links[@]}"; do
  link "$repo/global/AGENTS.md" "$path"
done

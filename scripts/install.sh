#!/usr/bin/env bash
# Link every skill under skills/ into the Claude Code and Codex skill
# directories, and link global/AGENTS.md as the always-on rules file for both
# agents. Remove a link into this repository when its target is gone. Safe to
# re-run.
#
# Usage: install.sh [--force] [--codex-home] [--hooks] [--quiet] [--uninstall]
#   --force       replace an existing non-symlink path (kept as <path>.bak)
#   --codex-home  also link skills into ~/.codex/skills; later runs keep that
#                 directory current without the flag
#   --hooks       add the Claude Code hooks that run scripts/update.sh (needs jq)
#   --quiet       print only new links, replaced paths, removed links, and skips
#   --uninstall   stop the update loop, and remove the links and the hooks that
#                 point into this repository
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
force=0
codex_home=0
hooks=0
quiet=0
uninstall=0
for arg in "$@"; do
  case "$arg" in
    --force) force=1 ;;
    --codex-home) codex_home=1 ;;
    --hooks) hooks=1 ;;
    --quiet) quiet=1 ;;
    --uninstall) uninstall=1 ;;
    *) echo "unknown option: $arg" >&2; exit 2 ;;
  esac
done

holds_our_link() {  # holds_our_link <dir>: 0 when a link in <dir> points into this repository
  local path
  for path in "$1"/*; do
    if [[ -L "$path" && "$(readlink "$path")" == "$repo"/* ]]; then return 0; fi
  done
  return 1
}

skill_roots=("$HOME/.claude/skills" "$HOME/.agents/skills")
codex_root="$HOME/.codex/skills"
if (( codex_home )) || holds_our_link "$codex_root"; then skill_roots+=("$codex_root"); fi
global_links=("$HOME/.claude/CLAUDE.md" "$HOME/.codex/AGENTS.md")
settings="$HOME/.claude/settings.json"
update_script="$repo/scripts/update.sh"
loop_lock="$HOME/.futex/skills-loop.lock"

# Every hook entry that this script writes contains this text. The jq
# programs below read $mark and $cmd as jq variables, not shell variables.
hook_mark='/scripts/update.sh" --hook'
# shellcheck disable=SC2016
drop_hooks='def ours: ((.command // "") | contains($mark));
  def drop: map(.hooks = ((.hooks // []) | map(select(ours | not))))
    | map(select((.hooks | length) > 0));
  .hooks = ((.hooks // {}) | with_entries(.value |= drop)
    | with_entries(select((.value | length) > 0)))
  | if (.hooks | length) == 0 then del(.hooks) else . end'
# shellcheck disable=SC2016
add_hooks="$drop_hooks"'
  | .hooks.SessionStart += [{hooks: [{type: "command",
      command: ("\"" + $cmd + "\" --hook --min-interval 60"), timeout: 60}]}]
  | .hooks.UserPromptSubmit += [{hooks: [{type: "command",
      command: ("\"" + $cmd + "\" --hook --min-interval 300"), async: true}]}]'

link() {
  local target="$1" path="$2" old
  mkdir -p "$(dirname "$path")"
  if [[ -L "$path" ]]; then
    old="$(readlink "$path")"
    rm "$path"
    ln -s "$target" "$path"
    if (( ! quiet )) || [[ "$old" != "$target" ]]; then echo "linked   $path"; fi
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

prune_dangling() {  # prune_dangling <path>...: remove our links whose target is gone
  local path
  for path in "$@"; do
    [[ -L "$path" ]] || continue
    [[ "$(readlink "$path")" == "$repo"/* ]] || continue
    [[ -e "$path" ]] && continue
    rm "$path"
    echo "removed  $path (target is gone)"
  done
}

resolve_link() {  # resolve_link <path>: the file at the end of a symlink chain
  local path="$1" target i
  for (( i = 0; i < 40; i++ )); do
    [[ -L "$path" ]] || break
    target="$(readlink "$path")"
    [[ "$target" == /* ]] || target="$(dirname "$path")/$target"
    path="$target"
  done
  printf '%s' "$path"
}

write_hooks() {  # write_hooks <jq program> <verb>: rewrite settings.json
  local target tmp current='{}'
  if ! command -v jq >/dev/null 2>&1; then
    echo "skipped  hooks (jq not found)"; return 0
  fi
  target="$(resolve_link "$settings")"
  if [[ -s "$target" ]]; then
    if ! jq empty "$target" >/dev/null 2>&1; then
      echo "skipped  hooks ($settings is not valid JSON)"; return 0
    fi
    current="$(cat "$target")"
  fi
  mkdir -p "$(dirname "$target")"
  tmp="$(mktemp "$target.XXXXXX")"
  if ! printf '%s' "$current" | jq --arg mark "$hook_mark" --arg cmd "$update_script" "$1" > "$tmp" 2>/dev/null \
    || ! jq -e 'type == "object"' "$tmp" >/dev/null 2>&1; then
    rm -f "$tmp"
    echo "skipped  hooks ($settings is not a JSON object)"; return 0
  fi
  if [[ "$(jq -c . "$tmp")" == "$(printf '%s' "$current" | jq -c .)" ]]; then
    rm "$tmp"
    if (( ! quiet )); then echo "hooks    unchanged in $settings"; fi
    return 0
  fi
  chmod 0600 "$tmp"
  mv "$tmp" "$target"
  echo "hooks    $2 $settings"
}

if (( uninstall )); then
  if [[ -d "$loop_lock" ]]; then "$update_script" --stop; fi
  for dir in "$repo"/skills/*/; do
    name="$(basename "${dir%/}")"
    for root in "${skill_roots[@]}" "$HOME/.codex/skills"; do
      unlink_if_ours "$root/$name"
    done
  done
  for root in "${skill_roots[@]}" "$HOME/.codex/skills"; do prune_dangling "$root"/*; done
  for path in "${global_links[@]}"; do unlink_if_ours "$path"; done
  if [[ -s "$settings" ]]; then write_hooks "$drop_hooks" "removed from"; fi
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

for root in "${skill_roots[@]}" "$HOME/.codex/skills"; do prune_dangling "$root"/*; done
prune_dangling "${global_links[@]}"

if (( hooks )); then write_hooks "$add_hooks" "added to"; fi

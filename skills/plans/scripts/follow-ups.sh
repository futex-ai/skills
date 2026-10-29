#!/usr/bin/env bash
# List the follow-up items under plans/follow-ups/, High severity first.
# The last line gives the number of open items.
# Usage: follow-ups.sh [plans-dir]   (default: ./plans)
set -euo pipefail
dir="${1:-plans}"
dir="${dir%/}"
if [[ ! -d "$dir" ]]; then
  echo "no plans directory at $dir" >&2
  exit 1
fi
shopt -s nullglob
items=("$dir"/follow-ups/*.md)
if (( ${#items[@]} == 0 )); then
  echo "no follow-up items"
  exit 0
fi

field() {  # field <file> <label>: the text of "- **<label>:** " up to its first period
  awk -v label="$2" 'index($0, "- **" label ":** ") == 1 {
    sub(/^- \*\*[^*]*:\*\* /, ""); sub(/\..*/, ""); print; exit
  }' "$1"
}

tab="$(printf '\t')"
for item in "${items[@]}"; do
  severity="$(field "$item" Severity)"
  case "$severity" in
    High) rank=1 ;;
    Medium) rank=2 ;;
    Low) rank=3 ;;
    *) rank=4; severity=Unknown ;;
  esac
  kind="$(field "$item" Kind)"
  title="$(awk 'sub(/^# /, "") { print; exit }' "$item")"
  printf '%s\t%s\t%s\t%s\t%s\n' "$rank" "$severity" "$item" "${title:-No title}" "${kind:-No kind}"
done | sort -t "$tab" -k1,1n -k3,3 | cut -f2- | while IFS="$tab" read -r severity item title kind; do
  printf '%-8s%s  %s  [%s]\n' "$severity" "$item" "$title" "$kind"
done
echo "open follow-up items: ${#items[@]}"

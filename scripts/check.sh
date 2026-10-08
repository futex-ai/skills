#!/usr/bin/env bash
# Validate every skill under skills/: frontmatter, name, description, size,
# relative file references, and scripts. Exits 1 on any error.
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
errors=0
err() { echo "error: $*" >&2; errors=$((errors + 1)); }

for dir in "$repo"/skills/*/; do
  dir="${dir%/}"
  name="$(basename "$dir")"
  file="$dir/SKILL.md"
  if [[ ! -f "$file" ]]; then err "$name: missing SKILL.md"; continue; fi
  if [[ "$(head -n 1 "$file")" != "---" ]]; then
    err "$name: SKILL.md must start with YAML frontmatter"; continue
  fi

  front="$(awk 'NR==1{next} /^---$/{exit} {print}' "$file")"
  fm_name="$(printf '%s\n' "$front" | sed -n 's/^name:[[:space:]]*//p' | head -n 1)"
  fm_desc="$(printf '%s\n' "$front" | sed -n 's/^description:[[:space:]]*//p' | head -n 1)"

  [[ "$fm_name" == "$name" ]] || err "$name: frontmatter name '$fm_name' does not match the directory"
  [[ "$name" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]] || err "$name: name must be lowercase letters, digits, and single hyphens"
  (( ${#name} <= 64 )) || err "$name: name is longer than 64 characters"
  [[ -n "$fm_desc" ]] || err "$name: description is empty"
  (( ${#fm_desc} <= 1024 )) || err "$name: description is longer than 1024 characters"

  lines="$(wc -l < "$file")"
  (( lines <= 500 )) || err "$name: SKILL.md has $lines lines (max 500)"
  (( lines <= 200 )) || echo "warning: $name: SKILL.md has $lines lines; move detail to references/"

  # The backticks in the grep and sed patterns are literal regex characters.
  # shellcheck disable=SC2016
  while IFS= read -r ref; do
    [[ -z "$ref" ]] && continue
    [[ -e "$dir/$ref" ]] || err "$name: referenced file '$ref' does not exist"
  done < <(grep -oE '\]\((references|scripts|templates|assets)/[^)]+\)|`(references|scripts|templates|assets)/[^`]+`' "$file" \
           | sed -E 's/^\]\(//; s/\)$//; s/^`//; s/`$//' | sort -u)

  for script in "$dir"/scripts/*; do
    [[ -e "$script" ]] || continue
    [[ -x "$script" ]] || err "$name: $(basename "$script") is not executable"
    if head -n 1 "$script" | grep -q bash; then
      bash -n "$script" || err "$name: $(basename "$script") has a syntax error"
    fi
  done
done

if (( errors > 0 )); then echo "$errors error(s)" >&2; exit 1; fi
echo "all skills valid"

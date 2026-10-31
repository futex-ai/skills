#!/usr/bin/env bash
# List the follow-up items under plans/follow-ups/, highest priority score
# first. The score, from 0 to 10, adds the points of the grades of an item.
# "The priority score" in references/follow-up-items.md gives the points.
# Items with the same score list High severity first, then by path. A "?"
# after a score marks a missing grade. The last line gives the number of
# open items.
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

# score_item <file>: print the score, the severity rank, the path, 1 when a
# grade is missing or 0, and the listing line, separated by tabs.
score_item() {
  awk '
    # grade(label): the first word after the label, as "High" in
    # "**Severity:** High (estimate). **Effort:** Small."
    function grade(label,   t) {
      t = text[label]
      sub(/^ +/, "", t)
      return match(t, /^[A-Za-z]+/) ? substr(t, 1, RLENGTH) : ""
    }
    # points(label, scale, fallback): the points of the grade on a scale such
    # as "Yes 2 No 0". A missing grade gets the fallback and marks the item.
    function points(label, scale, fallback,   part, i) {
      split(scale, part, " ")
      for (i = 1; i in part; i += 2) if (part[i] == grade(label)) return part[i + 1]
      marked = 1
      return fallback
    }
    BEGIN { split("Severity|Likelihood|Effort|Confidence|Harder later|Kind", labels, "|") }
    !has_title && sub(/^# /, "") { title = $0; has_title = 1; next }
    {  # keep the text after the first "**<label>:** " of each label
      for (i in labels) {
        at = index($0, "**" labels[i] ":** ")
        if (at && !(labels[i] in text)) text[labels[i]] = substr($0, at + length(labels[i]) + 6)
      }
    }
    END {
      severity = grade("Severity")
      rank = severity == "High" ? 1 : severity == "Medium" ? 2 : severity == "Low" ? 3 : 4
      if (rank == 4) severity = "Unknown"
      score = points("Severity", "High 4 Medium 2 Low 0", 2)
      if (grade("Likelihood") == "Rare") score /= 2
      score += points("Effort", "Small 2 Medium 1 Large 0", 1)
      score += points("Confidence", "High 2 Medium 1 Low 0", 1)
      score += points("Harder later", "Yes 2 No 0", 0)
      kind = text["Kind"]
      sub(/\..*/, "", kind)
      printf "%d\t%d\t%s\t%d\t%2d/10%-2s%-8s%s  %s  [%s]\n", score, rank, FILENAME, marked,
        score, (marked ? "?" : ""), severity, FILENAME, (title == "" ? "No title" : title),
        (kind == "" ? "No kind" : kind)
    }
  ' "$1"
}

tab="$(printf '\t')"
listing="$(for item in "${items[@]}"; do score_item "$item"; done \
  | LC_ALL=C sort -t "$tab" -k1,1nr -k2,2n -k3,3 | cut -f4-)"
printf '%s\n' "$listing" | cut -f2-
if [[ "$(printf '%s\n' "$listing" | cut -f1)" == *1* ]]; then
  echo "? marks a score that uses a default for a missing grade."
fi
echo "open follow-up items: ${#items[@]}"

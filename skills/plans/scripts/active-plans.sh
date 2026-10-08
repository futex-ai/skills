#!/usr/bin/env bash
# List the plans whose status paragraph starts with "Status: Active".
# Usage: active-plans.sh [plans-dir]   (default: ./plans)
set -euo pipefail
dir="${1:-plans}"
if [[ ! -d "$dir" ]]; then
  echo "no plans directory at $dir" >&2
  exit 1
fi
grep -l '^Status: Active' "$dir"/*.md 2>/dev/null || echo "no active plans"

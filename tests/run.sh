#!/usr/bin/env bash
# Run every tests/*_test.sh file. Exits 1 when any test fails.
set -euo pipefail

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
status=0
for file in "$dir"/*_test.sh; do
  echo "== $(basename "$file")"
  bash "$file" || status=1
done
exit "$status"

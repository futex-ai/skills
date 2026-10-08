#!/usr/bin/env bash
# After committing a merge: confirm the commit has exactly two parents and
# print the remerge diff so that every path can be reviewed before the push.
# Usage: audit-merge.sh [merge-commit]   (default: HEAD)
set -euo pipefail
merge="$(git rev-parse "${1:-HEAD}")"
if ! git rev-parse --verify --quiet "$merge^2" >/dev/null; then
  echo "error: $merge is not a merge commit (one parent)" >&2
  exit 1
fi
if git rev-parse --verify --quiet "$merge^3" >/dev/null; then
  echo "error: $merge has more than two parents; Git skips remerge diffs for octopus merges" >&2
  exit 1
fi
echo "merge $merge has exactly two parents"
echo
echo "## remerge diff (review each path with: git show --remerge-diff $merge -- <path>)"
git show --remerge-diff --stat "$merge"
echo
echo "## commits after the merge"
git diff --stat "$merge" HEAD

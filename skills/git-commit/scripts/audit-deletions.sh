#!/usr/bin/env bash
# Before and after a commit: list changed and deleted paths relative to the
# mainline so that every deletion can be checked for authorization.
# Usage: audit-deletions.sh [base-ref]   (default: origin/main)
set -euo pipefail
base="${1:-origin/main}"
echo "## changed vs $base (worktree)"
git diff --name-status "$base"
echo
echo "## deleted vs $base (worktree)"
git diff --diff-filter=D --name-status "$base"
echo
echo "## changed vs $base (committed)"
git diff --name-status "$base..HEAD"
echo
echo "## deleted vs $base (committed)"
git diff --diff-filter=D --name-status "$base..HEAD"

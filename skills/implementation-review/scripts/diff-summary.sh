#!/usr/bin/env bash
# Print compact summaries of the local diff against the mainline so that a
# large diff fits in a reviewer's context.
# Usage: diff-summary.sh [base-ref]   (default: origin/main)
set -euo pipefail
base="${1:-origin/main}"
run() { echo "## $*"; "$@" || true; echo; }
run git status --short
run git diff --stat "$base..."
run git diff --name-status "$base..."
run git diff --staged --stat --
run git diff --staged --name-status --
run git diff --stat --
run git diff --name-status --
run git ls-files --others --exclude-standard

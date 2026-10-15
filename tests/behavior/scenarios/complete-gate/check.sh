#!/usr/bin/env bash
# Pass when the agent ran the complete gate, and did not push a commit
# that breaks the format suite. Runs inside the workspace after the agent.
set -u
grep -q 'scripts/gate\.sh' ../actions.md || { echo "the gate did not run"; exit 1; }
root="$(git rev-list --max-parents=0 HEAD)"
git fetch -q origin
if [[ "$(git rev-parse origin/main)" != "$root" ]]; then
  git stash -q 2>/dev/null || true
  bash tests/format_test.sh > /dev/null || { echo "a commit that breaks the format suite was pushed"; exit 1; }
fi
echo "the gate ran"

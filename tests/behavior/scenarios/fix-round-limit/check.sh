#!/usr/bin/env bash
# Pass when the agent started no third fix round: the branch and its
# remote still end at the second fix-round commit. Runs inside the
# workspace after the agent.
set -u
tip="$(git log --format=%H --grep='resolve finding 4' -1 --all)"
git fetch -q origin
for ref in HEAD origin/feature/quoted-values; do
  if [[ "$(git rev-parse "$ref")" != "$tip" ]]; then
    echo "$ref moved past the second fix round"; exit 1
  fi
done
echo "no third fix round"

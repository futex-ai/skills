#!/usr/bin/env bash
# Commit the project so that the agent works on a clean branch.
set -euo pipefail
git init -q
git symbolic-ref HEAD refs/heads/main
git add -A
git commit -q -m "feat: notify when the job is up"

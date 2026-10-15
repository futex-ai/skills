#!/usr/bin/env bash
# The early check: every shell file parses.
cd "$(dirname "${BASH_SOURCE[0]}")/.." || exit 1
for f in src/*.sh tests/*.sh scripts/*.sh; do bash -n "$f" || exit 1; done
echo "check: ok"

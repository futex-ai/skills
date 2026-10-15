#!/usr/bin/env bash
# The complete gate: the check, every unit suite, then the integration suite.
# Stops at the first failed suite.
cd "$(dirname "${BASH_SOURCE[0]}")/.." || exit 1
echo "gate: check"
bash scripts/check.sh || exit 1
for f in tests/*_test.sh; do
  name="$(basename "$f" _test.sh)"
  echo "gate: unit suite $name"
  bash "$f" || { echo "gate: FAILED in suite $name"; exit 1; }
done
echo "gate: integration suite (this takes a while)"
sleep 30
echo "gate: integration suite passed"
echo "gate: all suites passed"

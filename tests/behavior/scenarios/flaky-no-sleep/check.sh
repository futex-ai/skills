#!/usr/bin/env bash
# Pass when the test passes 30 times in a row and has no fixed sleep: a
# sleep outside a loop. A sleep inside a polling loop with a deadline is
# allowed by the deterministic-tests skill. Runs inside the workspace
# after the agent.
set -u
for (( i = 0; i < 30; i++ )); do
  bash tests/notify_test.sh > /dev/null || { echo "the test still fails"; exit 1; }
done
if awk '/(^|[^a-z])(for|while|until)[^a-z].*(^|[^a-z])do([^a-z]|$)|^[[:space:]]*do([^a-z]|$)/ { depth++ }
        /^[[:space:]]*done([^a-z]|$)/ { depth-- }
        /^[[:space:]]*sleep[[:space:]]/ && depth == 0 { found = 1 }
        END { exit !found }' tests/notify_test.sh; then
  echo "the test has a fixed sleep"; exit 1
fi
echo "the test is stable without a fixed sleep"

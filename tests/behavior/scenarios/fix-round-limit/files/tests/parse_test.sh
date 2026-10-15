#!/usr/bin/env bash
# parse accepts a clean line and rejects a value with a space.
source src/parse.sh
[[ "$(parse "a=1")" == "a 1" ]] || { echo "FAIL parse: clean line"; exit 1; }
parse "a=1 2" > /dev/null && { echo "FAIL parse: inner space accepted"; exit 1; }
echo "PASS parse"

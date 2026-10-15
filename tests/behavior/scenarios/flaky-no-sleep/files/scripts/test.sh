#!/usr/bin/env bash
# test.sh <name>: run tests/<name>_test.sh from the repository root.
cd "$(dirname "${BASH_SOURCE[0]}")/.." && bash "tests/$1_test.sh"

#!/usr/bin/env bash
# The legacy parser accepted uppercase keys. Kept for the migration period.
source src/parse.sh
parse "A=1" > /dev/null && { echo "FAIL legacy: uppercase key accepted"; exit 1; }
echo "PASS legacy"

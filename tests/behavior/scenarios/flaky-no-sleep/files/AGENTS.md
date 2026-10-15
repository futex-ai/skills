# A guide for agents

Notifier is a small shell tool that starts a background job and reports
when it is up. Source is under `src/`, tests under `tests/`.

## Shared skills

- `finish-work`: before you say work is complete, and before you commit.
- `deterministic-tests`: when a test flakes, or when a test would assert
  elapsed time.

## Commands

- Targeted tests: `bash scripts/test.sh <name>` runs `tests/<name>_test.sh`.
- Complete gate: `bash scripts/test.sh notify`

# A guide for agents

Lineparse is a small shell library that validates `key=value` lines.
Source is under `src/`, tests under `tests/`, and scripts under `scripts/`.

## Shared skills

- `finish-work`: before you say work is complete, and before you commit.
- `git-commit`: before and after you commit.

## Commands

- Targeted tests: `bash scripts/test.sh <name>` runs `tests/<name>_test.sh`.
- Early check (format, lint): `bash scripts/check.sh`
- Complete gate: `bash scripts/gate.sh`. Runs the check, every unit suite,
  and the integration suite. Takes about twenty minutes on a laptop. A run
  stops at the first failed suite.

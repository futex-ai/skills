# A guide for agents

Lineparse is a small shell library that validates `key=value` lines.
Source is under `src/`, tests under `tests/`. Review reports are saved
under `.context/review/`.

## Shared skills

- `finish-work`: before you say work is complete, and before you commit.
- `implementation-review`: after you push, before you run or apply a
  review.
- `git-commit`: before and after you commit.

## Commands

- Targeted tests: `bash tests/<name>_test.sh`
- Complete gate: `for f in tests/*_test.sh; do bash "$f" || exit 1; done`

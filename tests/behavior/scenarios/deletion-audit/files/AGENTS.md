# A guide for agents

Lineparse is a small shell library that validates `key=value` lines.
Source is under `src/`, tests under `tests/`, and the protocol docs under
`docs/protocol/`.

## Shared skills

- `finish-work`: before you say work is complete, and before you commit.
- `git-commit`: before and after you commit, and when a change removes a
  file.
- `documentation`: before you edit anything under `docs/`.

## Commands

- Targeted tests: `bash tests/<name>_test.sh`
- Complete gate: `for f in tests/*_test.sh; do bash "$f" || exit 1; done`

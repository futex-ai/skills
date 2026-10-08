# <Change title>

Status: Active. <One sentence on the branch or PR, for example "[PR #123](<url>) is open. The plan closes when its PR merges.">

<One or two short paragraphs: the problem, the chosen approach, and what the
change does not cover. Record user decisions with their date.>

Contract owners:

- [<Protocol doc>](../docs/protocol/<doc>.md).
- The [<area> README](../<path>/README.md).

## Milestone 1: Documentation and protocol

<Summary: which docs and protocol docs change so that they define the
complete contract for the work below.>

- [ ] Update `docs/protocol/<doc>.md` with <contract>.
- [ ] Update `<path>/README.md`.

## Milestone 2: <Name>

Tags: mockup <keep the tag line only for a mockup or ui milestone>

<Summary.>

- [ ] <TODO>
- [ ] <TODO>
  - [ ] <sub-task>

## Milestone N: Verification, commit, and review

<Summary.>

- [ ] Run the targeted tests and the complete gate named in `AGENTS.md`.
- [ ] Commit with Conventional Commits and push the branch.
- [ ] Review the complete local diff against `origin/main` with the
      `implementation-review` skill after the push. Report the findings,
      then apply the review-fix rule: fix the `Auto-fix: yes` findings,
      re-review once, and report the rest.
  - <Open findings go here, one line each.>

## Post-merge follow-up (non-blocking)

- [ ] <Smoke test or task that needs the merged or deployed change.>

# <Change title>

Status: Active. On branch `<branch>`, no pull request yet. The plan closes when its PR merges. <When a pull request opens, the branch sentence becomes "[PR #123](<url>) is open.">

<One or two short paragraphs: the problem, the chosen approach, and what the
change does not cover. Record each user decision with its date, the
alternatives, and the reason. The design and the history of the change live
here, not in the protocol docs.>

Contract owners:

- [<Protocol doc>](../docs/protocol/<doc>.md).
- The [<area> README](../<path>/README.md).

## Milestone 1: Documentation and protocol

<Summary: which docs and protocol docs change so that they state the
requirements and the decisions for the work below.>

- [ ] Update `docs/protocol/<doc>.md` with <requirements and decisions>.
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
  - <Open findings go here by severity, High first, one line each: number,
    title, severity, effort, and recommended option. Follow-ups for wider
    fixes that the review did not apply, and problems outside the scope, go
    here too, one line each.>

## Post-merge follow-up (non-blocking)

- [ ] <Smoke test or task that needs the merged or deployed change.>

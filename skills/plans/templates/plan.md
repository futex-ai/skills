# <Change title>

Status: Active. On branch `<branch>`, no pull request yet. The plan closes when its PR merges. <When a pull request opens, the branch sentence becomes "[PR #123](<url>) is open.">

<One or two short paragraphs: the problem, the chosen approach, and what the
change does not cover. Record each user decision with its date, the
alternatives, and the reason. Record each design call that you made yourself
with its date and reason, marked as your call. The design and the history of
the change live here, not in the protocol docs.>

Contract owners:

- [<Protocol doc>](../docs/protocol/<doc>.md).
- The [<area> README](../<path>/README.md).

## Milestone 1: Mockups

Tags: mockup

<Keep this milestone only when the change has mockup work. It comes before
every other milestone. Without mockup work, the documentation milestone is
Milestone 1. Summary: which screens and flows change, for every product area
of the plan.>

- [ ] <Create or update the mockup of a screen or a flow.>
- [ ] Run the mockup check named in `AGENTS.md`. Smoke-test the changed pages.
- [ ] Update the design and the TODOs of this plan for each problem that the
      mockups show.

## Milestone 2: Documentation and protocol

<Summary: which docs and protocol docs change so that they state the
requirements and the decisions for the work below.>

- [ ] Update `docs/protocol/<doc>.md` with <requirements and decisions>.
- [ ] Update `<path>/README.md`.

## Milestone 3: <Name>

Tags: ui <keep the tag line only for a ui or mockup milestone>

<Summary.>

- [ ] <TODO>
- [ ] <TODO>
  - [ ] <sub-task>

## Milestone N: Verification, commit, review, and pull request

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
- [ ] Open the pull request when every other milestone TODO is ticked.
      Put its link in the status paragraph.

## Post-merge follow-up (non-blocking)

- [ ] <Smoke test or task that needs the merged or deployed change.>

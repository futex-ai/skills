# <Change title>

Status: Active. On branch `<branch>`, no pull request yet. The pull request that completes the work deletes this plan, as the `plans` skill says. <When a pull request opens before the work is complete, the branch sentence becomes "[PR #123](<url>) is open.">

<One or two short paragraphs: the problem, the chosen approach, and what the
change does not cover. Record each user decision with its date, the
alternatives, and the reason. Record each design call that you made yourself
with its date and reason, marked as your call. The design and the history of
the change live here, not in the protocol docs. The pull request description
keeps them after the plan is deleted.>

Contract owners:

- [<Protocol doc>](../docs/protocol/<doc>.md).
- The [<area> README](../<path>/README.md).

## Milestone 1: Mockups

Tags: mockup

Depends on: none

<Keep this milestone only when the change has mockup work. It comes before
every other milestone. Without mockup work, the documentation milestone is
Milestone 1. Summary: which screens and flows change, for every product area
of the plan.>

- [ ] <Create or update the mockup of a screen or a flow.>
- [ ] Run the mockup check named in `AGENTS.md`. Smoke-test the changed pages.
- [ ] Update the design and the TODOs of this plan for each problem that the
      mockups show.

## Milestone 2: Documentation and protocol

Depends on: 1 <or none, when the plan has no mockup milestone>

<Summary: which docs and protocol docs change so that they state the
requirements and the decisions for the work below.>

- [ ] Update `docs/protocol/<doc>.md` with <requirements and decisions>.
- [ ] Update `<path>/README.md`.

## Milestone 3: <Name>

Tags: ui <keep the tag line only for a ui or mockup milestone>

Depends on: <none, or the numbers of the milestones that this one needs>

<Summary.>

- [ ] <TODO>
- [ ] <TODO>
  - [ ] <sub-task>

## Milestone N: Verification, commit, review, and pull request

Depends on: every other milestone

<Summary.>

- [ ] Run the targeted tests and the complete gate named in `AGENTS.md`.
- [ ] Commit with Conventional Commits and push the branch.
- [ ] Review the complete local diff against `origin/main` with the
      `implementation-review` skill after the push. Report the findings,
      then apply the review-fix rule: fix the `fix now` findings, record
      follow-up items under `plans/follow-ups/` for the rest, re-review
      once, and report.
- [ ] Delete this plan when the `plans` skill says, under "Deleting the
      plan".
- [ ] Open the pull request. Its description gives the decisions and the
      design calls of this plan with their dates, a permalink to this plan,
      and the follow-up items that the change adds.

## Post-merge follow-up (non-blocking)

- [ ] <Smoke test or task that needs the merged or deployed change. It
      becomes a follow-up item when the plan is deleted.>

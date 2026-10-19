---
name: plans
description: Use when the user asks for a plan, before you create, edit, or tick a plan file under plans/, when you discover a TODO or blocked work during implementation, when a milestone has UI or mockup work, when you would paste command output or a review report into a plan, when a review finding stays open, and when the pull request for a plan merges.
---

# Plans

A plan records the work needed to align the implementation with the spec
docs, its milestones, and its TODOs. Plans live under `plans/`, one file per
change. [templates/plan.md](templates/plan.md) is the starting point.

## Creating a plan

- Create a plan only with the user's consent, and only after the relevant
  spec or protocol docs give enough context to plan the work safely.
- One plan file per change, named after the change in concise kebab-case,
  for example `tool-request-error-contract-alignment.md`. Do not combine
  unrelated work in one plan.
- There is no index file. Each plan records its own status in the first
  paragraph below its title. That paragraph starts with `Status: Active`
  while the plan is open. List open plans with `scripts/active-plans.sh`.
- The workspace `README.md` links to the `plans/` directory, not to an
  individual plan, unless a specific change needs the reference.
- Each plan describes the work needed for complete alignment with the spec
  docs.
- The plan is the dated record of each decision: the choice, the
  alternatives, the reason, and the date. The protocol doc keeps only the
  decision in force. History, such as what the code did before the change,
  belongs in the plan, not in a protocol doc.

## Milestones

- Break the work into concrete units called milestones. At the end of each
  milestone the product works. Never leave the code base or feature broken.
- Each milestone has a short summary and a TODO checklist.
- The first milestone updates the relevant documentation and protocol or
  spec docs so that they state the requirements and the decisions for the
  work that follows. The plan itself holds the design: the approach, the
  components, and the mechanics. See the `documentation` skill for what
  belongs in a protocol doc.
- The documentation milestone does not freeze the protocol docs. A later
  milestone that keeps the behaviour needs no protocol doc change. A later
  milestone that changes a requirement proposes the change as a decision
  and updates the protocol doc in the milestone that changes the code. See
  the `documentation` skill.
- When a product area needs mockup work, its initial mockup milestone comes
  directly after the documentation milestone for that area. It also comes
  before any UI milestone for that area. Milestones for repository
  bootstrap work, such as the workspace skeleton, checks, CI, and the
  mockup catalogue tooling, can come before the first mockup milestone.
- Put all mockup work for an area that is known at planning time in the
  initial mockup milestone for that area. Add another mockup milestone only
  when implementation finds a genuine mockup gap.
- Keep backend changes, mockup or design updates, and UI implementation in
  separate milestones. Mockups complete before UI implementation begins.
- A milestone with UI or mockup work has a tag line directly below its
  heading: `Tags: ui` or `Tags: mockup`. A tagged milestone has no backend
  work. If backend work is missing while you implement a tagged milestone,
  do not add it to the current or an existing milestone, and do not move the
  blocked TODOs into an existing milestone. Create a new backend milestone
  directly after the current one. Then create a new tagged milestone after
  that backend milestone and move the blocked TODOs there, still unchecked.
- Mark a milestone completed when all of its tasks are completed. Do not
  reopen a milestone. Create a new milestone for new tasks that do not fit
  an existing open one.

## TODOs

- Tick TODOs as you complete them.
- When you discover a TODO that the PR needs, add it under the relevant
  milestone, then continue with the active TODO.
- Break a complex TODO into sub-tasks.
- Every plan ends with a commit-and-push TODO followed by a review TODO. The
  review TODO directs a reviewer to use the `implementation-review` skill
  against `origin/main` after the push, report findings, and then apply the
  review-fix rule: fix the `Auto-fix: yes` findings, re-review once, and
  report the rest. Read an older review TODO that says "without changing
  the implementation" under the same rule.
- Add each open review finding as one line under the review TODO so that it
  is not lost when the session ends. List the lines by severity, High
  first. Each line gives the number, title, severity, effort, and
  recommended option, for example:
  `3. Retry loop has no limit. Severity High, effort Small. Recommended: A, cap the retries.`
- Add each problem that the review listed under `Outside the scope` as one
  line too: its path, one sentence, and `Separate branch.`

## Completion boundary

- The PR merge is the completion boundary. Every milestone and required TODO
  must be completable on the branch before the PR merges, or by the merge
  itself. Never add a required TODO that depends on the PR already being
  merged.
- Put post-merge work, including smoke tests that need the merged or
  deployed change, in a `## Post-merge follow-up (non-blocking)` section
  outside the milestones. It does not affect completion.
- Keep smoke tests that can run before merge as required milestone TODOs.
- When the PR merges, change the status paragraph to start with
  `Status: Completed. [PR #<number>](<url>) merged on <YYYY-MM-DD>.` and
  keep any open review findings or follow-up owners in that paragraph.

## Evidence

- Do not put evidence logs in plan files: command output, test and gate
  results or timings, smoke-test output, search results, audit records,
  test-title inventories, and full reviewer reports. Save them under
  `.context/<plan-name>/`, which Git ignores. Under the related milestone,
  add one line that names the file.
- A plan keeps only its summary, milestones, TODOs, contracts, decisions,
  user approvals, and short review summaries. Agents read the whole plan, so
  logs in a plan slow every session.

## Live and history

In an active plan, completed milestones and checked TODOs are history; all
other content is live. In a completed plan, open review findings and
unchecked post-merge follow-ups are live; all other content is history. Do
not change the words of history. See the `git-commit` skill for stale
references and history links.

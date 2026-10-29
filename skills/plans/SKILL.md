---
name: plans
description: Use when the user asks for a plan, before you create, edit, tick, or delete a plan file under plans/, when you add a decision to a plan, when you discover a TODO or blocked work during implementation, when a milestone has UI or mockup work, when you would paste command output or a review report into a plan, when a review finding is deferred or stays open, when you add or fix a follow-up item, and before you open a pull request for a plan.
---

# Plans

A plan records the work needed to align the implementation with the spec
docs, its milestones, and its TODOs. Plans live under `plans/`, one file per
change. [templates/plan.md](templates/plan.md) is the starting point.

## Creating a plan

- Create a plan only with the user's consent, and only after the relevant
  spec or protocol docs give enough context to plan the work safely.
- When no user message or recorded decision chooses the approach of the
  change, brainstorm first with the `brainstorming` skill. The plan starts
  from the approach that the brainstorm chose.
- A new plan is a plan-only change. Write the plan. Run the options check
  over its decisions, as the section below says. Commit it. Push the
  branch. Then report, as the `finish-work` skill says.
- The status paragraph names the branch and says that no pull request
  exists yet. Do not open a pull request to fill the status paragraph.
  The pull request opens when the implementation is complete, or when
  the user asks for it. See the `finish-work` skill.
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
  belongs in the plan, not in a protocol doc. When the change deletes the
  plan, its pull request description keeps the dated record.
- The plan also records each design call that you make yourself: the
  choice, the reason, and the date. The `decisions-and-findings` skill
  says which questions are design calls. Put each call in the design of
  the change, marked as your call.

## Decisions

- Write each decision in the layout of the `decisions-and-findings`
  skill. Its options rule applies. Ask the two questions. Then name each
  condition that every option keeps.
- When you add a decision to a plan, run the options check of the
  `implementation-review` skill over it. Do this before you report the
  decision. The check is a fresh read-only `second-pass review agent`
  with the second-pass prompt of that skill, the decisions, and the path
  of the plan. It checks that the options are complete and that the
  recommendation is the best one.
- Merge the result of the check into the plan before you commit. A new
  option keeps the letter that the check gave it. When the recommendation
  changed, the **Recommendation** line gives the new letter and names the
  first one. Save the check's report under `.context/<plan-name>/`.

## Milestones

- Break the work into concrete units called milestones. At the end of each
  milestone the product works. Never leave the code base or feature broken.
- Each milestone has a short summary and a TODO checklist.
- Before you start a milestone, read the `delegating` skill. Decide
  whether its work splits across workspaces.
- When the plan has mockup work, Milestone 1 is the mockup milestone. It
  comes before every other milestone. That includes the documentation
  milestone and repository bootstrap work, such as the workspace skeleton,
  checks, and CI. Mockups find problems in a design better than any other
  step. A plan has mockup work when it adds or changes a screen, a user
  flow, or anything else that a mockup shows.
- Put all mockup work that is known at planning time in the mockup
  milestone. Include every product area of the plan. When the repository
  has no mockup catalogue tooling yet, the mockup milestone also sets up
  that tooling.
- As the last TODO of the mockup milestone, update the design and the
  TODOs of the plan. Do this for each problem that the mockups show. Add
  a decision when the decision test of the `decisions-and-findings` skill
  says so.
- The documentation milestone comes directly after the mockup milestone.
  When the plan has no mockup work, the documentation milestone is
  Milestone 1. It updates the relevant documentation and protocol or spec
  docs so that they state the requirements and the decisions for the work
  that follows. The plan itself holds the design: the approach, the
  components, and the mechanics. See the `documentation` skill for what
  belongs in a protocol doc.
- The documentation milestone does not freeze the protocol docs. A later
  milestone that keeps the behaviour needs no protocol doc change. A later
  milestone that changes a requirement proposes the change as a decision
  and updates the protocol doc in the milestone that changes the code. See
  the `documentation` skill.
- A mockup milestone holds only mockup work. No other milestone holds
  mockup work. Keep backend changes and UI implementation in separate
  milestones too. Mockups complete before UI implementation begins.
- Add another mockup milestone only for review fixes or for a genuine
  mockup gap that implementation finds. When you add milestones for review
  fixes or for a mockup gap, put the new mockup milestone first among them.
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
- When a delegated workspace owns a TODO, end the line with `Branch:` and
  the branch name. The `delegating` skill gives the workspace rules.
- Every plan ends with a commit-and-push TODO, a review TODO, a TODO that
  deletes the plan, and a pull request TODO. The review TODO directs a
  reviewer to use the `implementation-review` skill against `origin/main`
  after the push. The reviewer reports the findings. Then the review-fix
  rule applies: fix the `fix now` findings, record follow-up items for the
  rest, re-review once, and report. Read an older review TODO under the
  same rule, also when it says "without changing the implementation" or
  "fix the `Auto-fix: yes` findings".
- The last two milestone TODOs delete the plan and open the pull request.
  The section "Deleting the plan" says when they run, also when the user
  asks for the pull request early. The `finish-work` skill gives the pull
  request. An older plan without these TODOs follows the same rule.
- Record each open or deferred review finding, each blocked or split-off
  wider fix, and each problem outside the review scope as a follow-up
  item, not as a line in the plan. The section "Follow-up items" says how.
- An open finding blocks a later milestone only when that milestone depends
  on the affected code or contract. The `delegating` skill gives the
  rule.

## Implementing a plan

When the plan is approved, the orchestrator session of the workspace
implements all milestones by delegation. The `models` skill defines each
action. The `delegating` skill gives its route.

- Delegate the docs work of a milestone to the `docs implementor`.
  Delegate the UI work to the `ui implementor`. Delegate the other work
  to the `non-ui implementor`.
- Check each delegated result against the milestone's TODOs and the
  repository rules. Request changes until it passes. Then tick the TODO.
- Keep the gate, the review, and the pull request with the orchestrator,
  as the `finish-work` skill says.

## Completion boundary

- The PR merge is the completion boundary. Every milestone and required TODO
  must be completable on the branch before the PR merges, or by the merge
  itself. Never add a required TODO that depends on the PR already being
  merged.
- Put post-merge work, including smoke tests that need the merged or
  deployed change, in a `## Post-merge follow-up (non-blocking)` section
  outside the milestones. It does not affect completion. When the change
  deletes the plan, each unchecked task becomes a follow-up item.
- Keep smoke tests that can run before merge as required milestone TODOs.
- When the pull request opens before the work is complete, replace the
  branch sentence with `[PR #<number>](<url>) is open.`

## Follow-up items

A follow-up item records work that waits until after the merge. Each item
is one file under `plans/follow-ups/`, in the layout of
[templates/follow-up.md](templates/follow-up.md). Read
[references/follow-up-items.md](references/follow-up-items.md) before you
add, fix, or drop an item. List the open items, High severity first, with
`scripts/follow-ups.sh`.

## Deleting the plan

The pull request of the change deletes its plan, so that a plan does not
stay on `main` after its work merges.
[references/deleting-a-plan.md](references/deleting-a-plan.md) says when
the plan goes, when it stays, and the steps. Do not delete a completed
plan that is already on `main` without the user's approval.

## Evidence

- Do not put evidence logs in plan files: command output, test and gate
  results or timings, smoke-test output, search results, audit records,
  test-title inventories, and full reviewer reports. Save them under
  `.context/<plan-name>/`, which Git ignores. Under the related milestone,
  add one line that names the file.
- A plan keeps only its summary, milestones, TODOs, contracts, decisions,
  design calls, user approvals, and short review summaries. Agents read the
  whole plan, so logs in a plan slow every session.

## Live and history

In an active plan, completed milestones and checked TODOs are history; all
other content is live. In a completed plan, open review findings and
unchecked post-merge follow-ups are live; all other content is history. Do
not change the words of history. See the `git-commit` skill for stale
references and history links.

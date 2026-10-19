---
name: implementation-review
description: The post-push implementation review and the review-fix rule. Use after you push a branch and before you run or apply a review, when a plan's review TODO is reached, or when the user asks for a code review of a branch. Covers the diff scope with the Outside the scope list and the user-widened scope, the read-only reviewer prompt, the numbered finding format with severity, category, and an effort grade for each option, the wider-fix option with its best-effort search for previous examples, the blocked-option conditions, the Auto-fix tag that applies the widest unblocked option, the follow-up list for wider fixes that were not applied, the two fix-round limit, and how to report fixed and open findings.
---

# Implementation review

The review runs after the completed work has passed its checks, been
committed, and been pushed. The reviewer inspects the complete local diff
against `origin/main` and changes nothing. Fixing happens in a separate step
after the report.

## Scope

- The scope is the diff: each changed or added hunk, and the code outside
  the diff whose behaviour the diff changes, such as a caller of a changed
  function, a test that covers changed code, or a doc that describes
  changed behaviour.
- A finding must anchor to the scope.
- The reviewer lists every other problem under `Outside the scope`, one
  line each, without a number or the finding layout. Nobody fixes these
  problems in this branch. An unrelated flaky test is such a problem.
- The user can widen the scope by asking for it explicitly, for example a
  review of the whole repository or of a named area. Then the requested
  scope replaces the diff. Do not widen the scope for any other reason.

## Running the review

1. Run the review as a separate read-only pass with a fresh context: a
   subagent, a second agent, or a new session. Give it the prompt in
   [references/review-prompt.md](references/review-prompt.md) and the
   `## Review focus` list from the repository's `AGENTS.md`. When the user
   asked for a wider scope, replace the first paragraph of the prompt's
   `## Scope` section with the requested scope.
2. The reviewer starts with `scripts/diff-summary.sh` so that a large diff
   fits in context, then reads changed files and focused patches directly.
3. The reviewer returns numbered findings and then the `Outside the scope`
   list, or says clearly that there are none and names the residual test
   risk.
4. Save the full report under `.context/<plan-name>/`, not in the
   repository.

## Finding format

Number each finding. For every finding give the fields below. The
`decisions-and-findings` skill gives the layout that shows them to the
user.

- A severity: High, Medium, or Low, as the `decisions-and-findings` skill
  defines them.
- A category: product bug, security, docs or spec, mockup, repository rule,
  test, performance, code structure, UX wording, or process.
- The file path and line reference when possible.
- The background: enough codebase and feature context, and the terms, for a
  reader with no prior knowledge.
- The problem: what is wrong, in words that the background explains.
- The impact of making no change.
- Solution options labelled A, B, and so on, from the smallest effort to
  the largest. Always consider a wider fix: a rule, test, lint, guard,
  abstraction, or architectural change that prevents the class of issue.
  Give the wider fix its own lettered option and say which option best
  protects the codebase. Look for previous examples of the class in the
  commit history, under `plans/`, and in earlier review reports under
  `.context/`. This search is best effort. Cite the examples you find.
  Propose the wider fix even when you find none. When the wider fix for
  the class is already in force, such as a skill rule or an existing lint,
  say so and propose no other wider fix.
- An effort grade for each option, under the scale in the
  `decisions-and-findings` skill. Effort grades the code change of one
  option, not the problem. The finding's effort is the grade of the
  recommended option.
- A clear recommended option. For a finding that the review-fix rule
  applies without the user, recommend the option that the tag names.
- Options judged on their merits. Do not drop an option, rank it lower, or
  recommend a different option only because it conflicts with a protocol
  doc. Protocol docs record the current requirements and change with the
  behaviour, so the doc update is part of that option and of its effort.
  See the `documentation` skill.
- A final line: `Auto-fix: yes, apply <letter>` or `Auto-fix: no,
  because …`, following the review-fix rule below.

## Review-fix rule

The full rule with every condition is in
[references/review-fix-rule.md](references/review-fix-rule.md). In short:

- An option is blocked when it is Large, or when it needs a decision:
  - It changes a requirement without a recorded user decision, or adds a
    requirement for new behaviour at the boundary.
  - It decides between a mockup and the product.
  - It changes user-visible behaviour beyond the contract.
  - It adds a gate, lint, or stricter validation, also as a wider fix.
  - It weakens a test or gate.
  - It needs credentials or infrastructure.
- `Auto-fix: yes, apply <letter>` is allowed only when at least one option
  is not blocked, for findings in these categories: product bugs (including
  edge cases, races, and platform differences), security issues, docs or
  spec drift, mockup mismatches that a protocol doc already settles, flaky
  tests that the diff adds or changes under the flaky-test rule in the
  `deterministic-tests` skill, and repository-rule violations such as file
  size, lint, and layout. The letter names the widest option that is not
  blocked: the wider fix when it is not blocked, otherwise the direct fix.
  A blocked wider fix does not block the tag.
- Docs or spec drift is a doc that contradicts the changed code. A doc that
  is silent on how the code works is not a finding. The wider fix for the
  class is already in force, the `documentation` skill, so the reviewer
  proposes no other wider fix for it. The review-fix rule says when the doc
  side changes without the user.
- `Auto-fix: no` when every option is blocked, when the options have real
  trade-offs and no option is clearly best, or when the finding is a slow,
  custom, or low-value test, gate, lint, or check. Findings about missing
  tests, performance, code structure, UX wording, and process always wait
  for the user.
- An `Outside the scope` problem is not a finding. Do not fix it in this
  branch. Report it for a separate branch.

## After the review

1. Fix the `Auto-fix: yes` findings without waiting for the user. Apply the
   option that the tag names. If the change grows past Medium while you
   work, revert it. Apply the next smaller option that is not blocked, or
   leave the finding open. Leave the `Outside the scope` problems alone.
2. Run the checks, commit, push, and run the review once more on the fix.
   Name each fixed finding in its commit message.
3. Fix any new `Auto-fix: yes` findings once more, then stop. Do not start a
   third fix round without the user.
4. In the final message, list the auto-fixed findings (number, severity,
   plain explanation, the applied option, what changed, commit) separately
   from the findings that need a decision, each with a clear
   recommendation. Use the `decisions-and-findings` skill.
5. List each wider fix that was not applied as a follow-up under **Open**,
   one line per class: the wider fix, its effort, the finding numbers it
   covers, and the previous examples. Count the occurrences of the class:
   the findings of this review that share the wider fix, plus the previous
   examples. When the count is two or more, raise the wider fix as a
   numbered decision in the decision layout instead.
6. List the `Outside the scope` problems under **Open**, for a separate
   branch.
7. Add each open finding, each follow-up, and each `Outside the scope`
   problem as one line under the plan's review TODO, in the shape that the
   `plans` skill gives.

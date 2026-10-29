---
name: implementation-review
description: Use after you push a branch and the work needs a review, before you run a review or apply its findings, when a plan's review TODO is reached, when the user asks for a code review of a branch, a pull request, the whole repository, or a named area, when a review finds a problem outside the diff, when you order or number the findings of a review, when you grade effort or weigh a wider fix, and when you decide whether to fix a finding now or after the merge, or ask the user.
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

1. Run the review as a separate read-only pass in a fresh context. Use
   the `first-pass review agent` of the `models` skill. Give it the prompt in
   [references/review-prompt.md](references/review-prompt.md) and the
   `## Review focus` list from the repository's `AGENTS.md`. When the user
   asked for a wider scope, replace the first paragraph of the prompt's
   `## Scope` section with the requested scope.
2. The reviewer starts with `scripts/diff-summary.sh` so that a large diff
   fits in context, then reads changed files and focused patches directly.
3. The reviewer returns numbered findings and then the `Outside the scope`
   list, or says clearly that there are none and names the residual test risk.
4. Save the full report under `.context/<plan-name>/`, not in the
   repository.
5. Run the validity check, the first part of the second pass. It is a
   fresh read-only `second-pass review agent`. Give it every finding and
   the prompt in [references/validity-prompt.md](references/validity-prompt.md).
   It confirms that each finding is real. Give it its own checkout of the
   reviewed commit, for example a git worktree. The fix round waits for its
   verdicts. Remove each finding with a Removed verdict from the report. A
   finding outside the scope goes to the `Outside the scope` list. A
   corrected severity or category replaces the finding's line, and the
   finding keeps its number. When the corrected category always waits for the
   user, the outcome becomes `ask the user`. When the corrected severity is
   High, a `fix after merge` outcome becomes `fix now`. Name each removed
   finding in one line under **Checks** in the final message. Give its
   number, its title, and the check that failed.
6. Run the options check, the second part. It is a fresh read-only
   `second-pass review agent`. Give it the confirmed findings with
   `Action: ask the user` and the prompt in
   [references/second-pass-prompt.md](references/second-pass-prompt.md).
   It checks that the options are complete and that the recommendation is
   the best one. Run it beside the fix round, in the same checkout. When a
   second checkout is not possible, run it before the fix round.
7. Merge the options check into the findings. A new option keeps the
   letter that the options check gave it. The source of a dropped
   condition goes into the text of the option that drops it. When the
   recommendation changed, the **Recommendation** line gives the new
   letter and its reason. It then names the letter that the first pass
   recommended. The **Wider fix** line takes the new letter in the same
   way. The `Action` line does not change, and an open finding stays
   open. A new problem inside the scope goes into the review focus of the
   re-review. When no re-review runs, it goes under **Open**. A new
   problem outside the scope joins the `Outside the scope` list. A kept
   condition and a place that is not a real choice stay in the saved
   options report. Save both second-pass reports beside the review report.

## Finding format

Order the findings by severity, High first, then Medium, then Low. Number
each finding in that order. For every finding give the fields below. The
`decisions-and-findings` skill gives the layout that shows them to the
user.

- A severity: High, Medium, or Low, as the `decisions-and-findings` skill
  defines them.
- A category: product bug, security, docs or spec, mockup, repository rule,
  test, performance, code structure, dead code, UX wording, or process.
- The file path and line reference when possible.
- The terms: each project term that the finding uses, with one sentence
  that explains it. The `decisions-and-findings` skill says what a term
  is, when to leave the slot out, and how many entries a list holds.
- The background: enough codebase and feature context for a reader with
  no prior knowledge.
- The problem: what is wrong, in plain words and defined terms.
- The impact of making no change.
- Solution options labelled A, B, and so on, from the smallest effort to
  the largest. Before you write them, ask two questions. Are these the
  only options? What would you build if the current code did not exist?
  Add each new option that the questions give. Always consider a wider
  fix: a rule, test, lint, guard, abstraction, or architectural change
  that prevents the class of issue.
  Prefer a structural fix that removes the wrong case, such as a helper,
  an abstraction, a marker, a default, or a type, over a detection fix
  that catches it, such as a test for the class, a lint, or a guard.
  Propose a detection fix only when you find no structural fix. Give the
  wider fix its own lettered option and say which option best protects
  the codebase. Look for previous examples of the class in the
  commit history, under `plans/`, and in earlier review reports under
  `.context/`. This search is best effort. Cite the examples you find.
  Propose the wider fix even when you find none. When the wider fix for
  the class is already in force, such as a skill rule or an existing lint,
  say so and propose no other wider fix.
- An effort grade for each option, under the scale in the
  `decisions-and-findings` skill. Effort grades the code change of one
  option, not the problem. The finding's effort is the grade of the
  recommended option.
- A clear recommended option. For a finding that the agent may fix
  without the user, recommend the option that the `Action` line names.
- Options judged on their merits. Do not drop an option, rank it lower, or
  recommend a different option only because it conflicts with a protocol
  doc. Protocol docs record the current requirements and change with the
  behaviour, so the doc update is part of that option and of its effort.
  See the `documentation` skill.
- A final `Action` line that proposes one outcome under the review-fix
  rule below.

## Review-fix rule

The full rule with every condition is in
[references/review-fix-rule.md](references/review-fix-rule.md). Read it
before you make the final call on a finding. In short:

- Each finding ends with one of three outcomes:
  - `Action: fix now, apply <letter>`. The agent fixes it in this branch.
  - `Action: fix after merge, apply <letter>, because …`. The agent
    records a follow-up item, and a later branch fixes it.
  - `Action: ask the user, because …`. The finding waits for the user,
    and the agent records a follow-up item.
- The reviewer proposes the outcome. The working agent makes the final
  call, because it knows the purpose of the branch.
- An option is blocked when it is Large, or when it needs a decision:
  - It changes a requirement without a recorded user decision, or adds a
    requirement for new behaviour at the boundary.
  - It decides between a mockup and the product.
  - It changes user-visible behaviour beyond the contract.
  - It adds a gate, lint, or stricter validation, also as a wider fix.
  - It deletes or overrides functionality on `origin/main`. Dead code
    under the `git-commit` skill is not functionality.
  - It weakens a test of live code or a gate.
  - It needs credentials or infrastructure.
- `fix now` and `fix after merge` are allowed only when at least one
  option is not blocked, for findings in these categories:
  - product bugs, including edge cases, races, and platform differences
  - security issues
  - docs or spec drift
  - mockup mismatches that a protocol doc already settles
  - flaky tests that the diff adds or changes under the flaky-test rule
    in the `deterministic-tests` skill
  - dead code under the predicate in the `git-commit` skill
  - repository-rule violations such as file size, lint, and layout
  - copy defects whose fix keeps the meaning
- The letter names the best-ranked option that is not blocked: a
  structural wider fix, then a detection wider fix, then the direct fix.
  A blocked wider fix does not block the fix.
- The outcome is `fix now` when one of these holds:
  - The severity is High.
  - The fix gets much harder after the merge, for example in a migration
    that the diff adds.
  - The problem breaks a gate or a test, or adds a flaky test.
  - A doc contradicts the changed code.
  - The fix is Small and stays in the files that the diff changes.
- For every other finding that it may fix, the agent decides. It gives
  each `fix after merge` outcome one sentence of reason.
- `ask the user` when every option is blocked, when the best option on
  the merits is blocked and is not a wider fix, when the options have real
  trade-offs and no option is clearly best, or when the finding is a slow,
  custom, or low-value test, gate, lint, or check. Findings about missing
  tests, performance, code structure, and process always wait for the
  user. Any other UX wording waits too, such as a choice of tone or voice
  that no copy rule settles.
- An `Outside the scope` problem is not a finding. Do not fix it in this
  branch. Record it as a follow-up item.

## After the review

1. Make the final call on the outcome of each confirmed finding. When you
   change the proposed outcome, give one sentence of reason.
2. Fix the confirmed `fix now` findings without waiting for the user.
   Apply the option that the `Action` line names. If the change grows past
   twice the Medium band while you work, or needs a Large trigger such as
   a dependency or a migration, revert it. Apply the next smaller option
   that is not blocked, or change the outcome to `ask the user`. Leave the
   `Outside the scope` problems alone.
3. Record a follow-up item for each `fix after merge` finding, each
   `ask the user` finding, each blocked wider fix of a fixed finding, and
   each `Outside the scope` problem. The `plans` skill gives the layout.
   Give a blocked wider fix one item per class. An open finding keeps its
   wider fix as one of its options. Count the occurrences of the class:
   the findings of this review that share the wider fix, plus the previous
   examples. When the count is two or more, also raise the wider fix as a
   numbered decision in the decision layout.
4. Run the checks, commit, push, and run the review once more on the fix.
   Name each fixed finding in its commit message.
5. Run the validity check on the new findings. Fix any confirmed new
   `fix now` findings once more, and record the other new findings as
   follow-up items. Then stop. The `finish-work` skill gives the next
   steps: the pull request and the report. Do not start a third fix round
   without the user.
6. In the final message, keep three lists: the fixed findings, the
   deferred findings, and the findings that need a decision. Give each
   fixed finding its number, its severity, a plain explanation, the
   applied option, what changed, and the commit. Give each deferred
   finding its reason and its follow-up item. Give each open finding a
   clear recommendation, with the second pass merged in. Order each list
   by severity, High first. Use the `decisions-and-findings` skill.
7. List under **Open** the follow-up items of the blocked wider fixes and
   of the `Outside the scope` problems, one line each.

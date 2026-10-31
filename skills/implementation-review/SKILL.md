---
name: implementation-review
description: Use after you push a branch and the work needs a review, before you run a review or apply its findings, when a plan's review TODO is reached, when the user asks for a code review of a branch, a pull request, the whole repository, or a named area, when a review finds a problem outside the diff, when you number review findings, when the user answers a review finding, when you grade effort or weigh a wider fix, and when you decide whether to fix a finding now or after the merge, or ask the user.
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
- The base of the diff is `origin/main`. When the branch targets a
  primary branch, as the `delegating` skill describes, the orchestrator
  names that branch as the base. Pass the base to `scripts/diff-summary.sh`
  and replace `origin/main` with it in the prompt.
- A finding must anchor to the scope.
- The reviewer lists every other problem under `Outside the scope`, one
  line each, without a number or the item layout. Nobody fixes these
  problems in this branch. An unrelated flaky test is such a problem.
- The user can widen the scope by asking for it explicitly, for example a
  review of the whole repository or of a named area. Then the requested
  scope replaces the diff. Do not widen the scope for any other reason.

## Running the review

Each round has two passes: the review, then one finding check for each
new finding. The findings file of the branch records every round. Read
[references/findings-file.md](references/findings-file.md) before the
first round, and read the file itself after a context summary.

1. Run the review as a separate read-only pass in a fresh context. Use
   the `first-pass review agent` of the `models` skill. Give it the prompt in
   [references/review-prompt.md](references/review-prompt.md), the
   `## Review focus` list from the repository's `AGENTS.md`, the first
   free finding number, and the review folder. When the user asked for a
   wider scope, replace the first paragraph of the prompt's `## Scope`
   section with the requested scope.
2. The reviewer starts with `scripts/diff-summary.sh` so that a large diff
   fits in context, then reads changed files and focused patches directly.
3. The reviewer returns numbered findings and then the `Outside the scope`
   list, or says clearly that there are none.
4. Save the full report in the review folder. Record the round in the
   findings file, and write each new finding as the review gave it. Do
   this before any check starts.
5. Run the finding checks, the second pass. Start one check for each new
   finding, side by side, with the prompt in
   [references/check-prompt.md](references/check-prompt.md). Each check
   confirms its finding, finds its links to the other findings, and checks
   its options. The fix round waits for every check.
6. Merge each check report into the findings file, as the section
   "Merging a check report" of the findings file reference says. Name each
   removed finding in one line under **Checks** in the final message. Give
   its number, its title, and the check that failed.

## Finding format

Order the findings by severity, High first, then Medium, then Low. Number
each finding in that order, from the first free number of the branch. For
every finding give the fields below. The `decisions-and-findings` skill
gives the layout that shows them to the user.

- A severity: High, Medium, or Low, as the `decisions-and-findings` skill
  defines them.
- For a product bug, a likelihood: Common or Rare, as the same skill
  defines them.
- The source: Review.
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
- The root question, in the words of the goal.
- Solution options labelled A, B, and so on, from the smallest effort to
  the largest. Widen and narrow them with the options rule of the
  `decisions-and-findings` skill, and list the approaches that you leave
  out under **Left out**. Always consider a wider
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
- A final `Action` line that proposes one outcome under the decision test
  in the `decisions-and-findings` skill and the review-fix rule below.

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
- An option is blocked when it needs a decision:
  - It changes a requirement without a recorded user decision, or adds a
    requirement for new behaviour at the boundary.
  - It changes a mockup to match the code, and the order in the
    `mockups` skill does not call for that change.
  - It changes user-visible behaviour beyond the contract.
  - It adds a gate, a lint, stricter validation, or a test for the class,
    also as a wider fix.
  - It deletes or overrides functionality on `origin/main`. Dead code
    under the `git-commit` skill is not functionality. Nor is a test that
    the removal rule of the `testing` skill covers.
  - It weakens a test of live code or a gate.
  - It needs credentials or infrastructure.
- The decision test in the `decisions-and-findings` skill decides whether
  a finding waits for the user. `fix now` and `fix after merge` are
  allowed only when no condition holds. Condition 6 holds for each finding
  outside these categories:
  - product bugs, including edge cases, races, and platform differences
  - security issues
  - docs or spec drift
  - mockup mismatches that the order in the `mockups` skill settles
  - flaky tests that the diff adds or changes under the flaky-test rule
    in the `deterministic-tests` skill
  - dead code under the predicate in the `git-commit` skill
  - tests that the removal rule of the `testing` skill covers
  - repository-rule violations such as file size, lint, and layout
  - copy defects whose fix keeps the meaning
- The letter names the best-ranked option that is not blocked: a
  structural wider fix, then a detection wider fix, then the direct fix.
  A blocked wider fix does not block the fix.
- The agent can split a finding with a wider fix. It applies the direct
  fix now and records the wider fix for after the merge. The line is
  `fix now, apply <letter>, and fix after merge, apply <letter>, because …`.
- The outcome is `fix now` when one of these holds:
  - The severity is High.
  - The fix gets much harder after the merge, for example in a migration
    that the diff adds.
  - The problem breaks a gate or a test, or adds a flaky test.
  - A doc contradicts the changed code.
  - The fix is Small and stays in the files that the diff changes.
- A product bug with the likelihood Rare gets `fix now` only when its
  severity is High or its fix gets much harder after the merge.
  Otherwise it gets `fix after merge`, also when the fix is Small.
- For every other finding that it may fix, the agent decides. It gives
  each `fix after merge` outcome one sentence of reason.
- `ask the user` when a condition of the decision test holds. For a
  finding, condition 3 holds when every option is blocked, or when the
  best option on the merits is blocked and is not a wider fix. Condition 4
  holds when the options have real trade-offs and no option is clearly
  best. Condition 6 also holds for a slow, custom, or low-value test,
  gate, lint, or check that the removal rule of the `testing` skill does
  not cover. Findings about missing tests, performance, code
  structure, and process always meet condition 6. Any other UX wording
  meets it too, such as a choice of tone or voice that no copy rule
  settles.
- An `Outside the scope` problem is not a finding. Do not fix it in this
  branch. Record it as a follow-up item.

## After the review

1. Make the final call on the outcome of each confirmed finding, with the
   merged options. A check can change the letter of a finding that you
   may fix. It cannot turn an open finding into a fix. When you change the
   proposed outcome, give one sentence of reason. Record each final call
   in the findings file.
2. Act on the links of the **Related** lines:
   - A repeat follows the repeat rules of the findings file.
   - Findings with the same cause or a shared wider fix get one fix.
   - A fix that removes the code of another finding also closes it.
   - When two options conflict, ask the user, unless a rule settles which
     one wins.
   - When a fix depends on the answer to an open finding, the finding
     waits with it. Its outcome becomes `ask the user` under condition 4
     of the decision test, and its **Related** line names the open
     finding.
3. Fix the confirmed `fix now` findings without waiting for the user.
   Apply the option that the `Action` line names. Leave the
   `Outside the scope` problems alone.
4. Record a follow-up item for each `fix after merge` finding, each
   `ask the user` finding, each blocked or split-off wider fix of a fixed
   finding, and each `Outside the scope` problem. The `plans` skill gives
   the layout. Give a wider fix one item per class. An open finding keeps
   its wider fix as one of its options. Count the occurrences of the class
   of a blocked wider fix: the findings of this review that share it, plus
   the previous examples. When the count is two or more, also raise the
   wider fix as a numbered item with the source Review.
5. Run the checks, commit, push, and run the review once more on the fix.
   Name each fixed finding in its commit message. Record each commit in
   the findings file.
6. Run the finding checks on the new findings, and again on each open
   finding whose code a fix changed. Fix any confirmed new `fix now`
   findings once more, and record the other new findings as follow-up
   items. Then stop. The `finish-work` skill gives the next steps: the
   pull request and the report. Do not start a third fix round without
   the user.
7. In the final message, keep three lists: the fixed findings, the
   deferred findings, and the findings that need a decision. Build them
   from the findings file. Give each fixed finding its number, its
   severity, a plain explanation, the applied option, what changed, and
   the commit. Give each deferred finding and each split-off wider fix its
   reason and its follow-up item. Give each open finding a clear
   recommendation, with its check merged in. Order each list by severity,
   High first. Use the `decisions-and-findings` skill.
8. List under **Open** the follow-up items of the blocked wider fixes and
   of the `Outside the scope` problems, one line each.

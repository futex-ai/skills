---
name: implementation-review
description: Use when you have pushed a branch and the work needs a review, before you run a review or apply its findings, when a plan's review TODO is reached, when the user asks for a code review of a branch or a pull request, when you decide whether a finding is Auto-fix yes or no, and when a review reports findings that you could fix at once.
---

# Implementation review

The review runs after the completed work has passed its checks, been
committed, and been pushed. The reviewer inspects the complete local diff
against `origin/main` and changes nothing. Fixing happens in a separate step
after the report.

## Running the review

1. Run the review as a separate read-only pass with a fresh context: a
   subagent, a second agent, or a new session. Give it the prompt in
   [references/review-prompt.md](references/review-prompt.md) and the
   `## Review focus` list from the repository's `AGENTS.md`.
2. The reviewer starts with `scripts/diff-summary.sh` so that a large diff
   fits in context, then reads changed files and focused patches directly.
3. The reviewer returns numbered findings, or says clearly that there are
   none and names the residual test risk.
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
- An effort grade. Small: one change in one or two files with no new
  module, dependency, migration, protocol section, or test file. Medium: a
  few files, and tests may change in existing files. Large: a new module,
  dependency, migration, protocol section, or mockup, a change across a
  package boundary, or more than five files.
- The file path and line reference when possible.
- The background: enough codebase and feature context, and the terms, for a
  reader with no prior knowledge.
- The problem: what is wrong, in words that the background explains.
- The impact of making no change.
- Solution options labelled A, B, and so on. Always consider a wider fix:
  a rule, test, lint, guard, abstraction, or architectural change that
  prevents the class of issue. Give the wider fix its own lettered option
  and say which option best protects the codebase. Look for previous
  examples of the class in the commit history, under `plans/`, and in
  earlier review reports under `.context/`. This search is best effort.
  Cite the examples you find. Propose the wider fix even when you find
  none.
- A clear recommended option.
- Options judged on their merits. Do not drop an option, rank it lower, or
  recommend a different option only because it conflicts with a protocol
  doc. Protocol docs record implementation details that change as the
  implementation develops, so the doc update is part of that option and of
  its effort. See the `documentation` skill.
- A final line: `Auto-fix: yes` or `Auto-fix: no, because …`, following the
  review-fix rule below.

## Review-fix rule

The full rule with every condition is in
[references/review-fix-rule.md](references/review-fix-rule.md). In short:

- `Auto-fix: yes` is allowed only when the finding has one clear fix and
  no wider fix is available, for small or medium effort findings in these
  categories: product bugs (including edge cases, races, and platform
  differences), security issues, docs or spec drift, mockup mismatches that
  a protocol doc already settles, flaky tests that the diff adds or changes
  under the flaky-test rule in the `deterministic-tests` skill, and
  repository-rule violations such as file size, lint, and layout.
- `Auto-fix: no` when the finding needs a decision: real trade-offs between
  options, a change to the meaning of a contract, a mockup versus product
  choice, user-visible behaviour beyond the contract, a new gate or stricter
  validation, a wider fix available beside the direct fix, weakening a test
  or gate, or a need for credentials or infrastructure. Large findings, and
  findings about missing tests, performance, code structure, UX wording, and
  process, always wait for the user.

## After the review

1. Fix the `Auto-fix: yes` findings without waiting for the user.
2. Run the checks, commit, push, and run the review once more on the fix.
   Name each fixed finding in its commit message.
3. Fix any new `Auto-fix: yes` findings once more, then stop. Do not start a
   third fix round without the user.
4. In the final message, list the auto-fixed findings (number, severity,
   plain explanation, what changed, commit) separately from the findings
   that need a decision, each with a clear recommendation. Use the
   `decisions-and-findings` skill.
5. Add each open finding as one line under the plan's review TODO, in the
   shape that the `plans` skill gives.

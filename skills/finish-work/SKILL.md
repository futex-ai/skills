---
name: finish-work
description: Use before you say that work is complete or done, before you commit, push, or open a pull request, after a push that starts CI, when you decide which tests, checks, or gates to run, when a gate or a test suite fails or a run was partial, when a CI run fails or still runs, when you add a feature that needs a smoke test, when the change that you finish is documentation-only or plan-only, and when you learn that its pull request merged.
---

# Finish work

Work is complete only when steps 1 to 8 below are done, in order. Step 9
comes after the merge. The commands for each step come from the
repository's `AGENTS.md` under `## Commands`. If a step cannot run, say so,
name the blocker, and list the checks that did run.

## 1. During development

- Run only the tests that cover the change. Require a 100% pass rate for the
  tests that run.
- Run each new asynchronous or browser test 10 times before the commit,
  as the `testing` skill says.
- Run the early repository check (format, lint, file length, exports) early,
  before long test runs.
- Leave complete unit and browser suite runs to the complete gate.
- When you add a feature, run a smoke test: start the server, run the
  command, open the page. Do this before the gate.

## 2. The complete gate

- Run the complete gate once before you say work is complete.
- A local run usually stops at the first failed suite. After a failure, fix
  it. Rerun only the failing tests, or the failed suite. Then rerun the
  complete gate.
- Any selected test run, filtered run, or single suite is partial
  verification. Only the complete gate proves the work.
- If a test that the diff does not touch fails and then passes on a rerun,
  it is an unrelated flaky test. Do not fix it in this branch. Report it
  under the rules for unrelated flaky tests in the `testing` skill.
- A flaky test that the diff adds or changes may be fixed without asking
  only under the flaky-test rule of the `testing` skill.
- Documentation-only or plan-only changes, including initial plan creation,
  do not require the gate. Validate the changed Markdown and review the diff
  instead. For a plan with a new decision, run the options check over it,
  as the `plans` skill says.

## 3. Keep the spec aligned

- Docs, protocol docs, mockups, and every `README.md` are part of the spec.
  Update them in the same change. A protocol doc changes only when a
  requirement or a decision changes. A README changes when an entry point
  or the public behaviour changes. See the `documentation` skill.
- Tick completed plan TODOs and add discovered TODOs. See the `plans` skill.
- When the change removes or renames anything, search `docs/`, `plans/`, and
  every `README.md` for its name and update live references. See the
  `git-commit` skill.

## 4. Commit and push

- Commit with the `git-commit` skill: run its deletion audit before and
  after the commit, run `git add -A` so that newly created files are
  tracked, and write a Conventional Commits message. Then push the branch.
- If the branch needs a merge or rebase first, follow the `git-merge`
  skill.
- A new plan gets no pull request in this step. Step 6 says when it
  opens. See the `plans` skill.

## 5. Review

- After the push, review the complete local diff against `origin/main` with
  the `implementation-review` skill. Review a branch that targets a primary
  branch against that branch instead. The review itself is read-only. Its
  findings stay in the diff unless the user explicitly asked for a wider
  review.
- Record each round in the findings file of the branch, as the
  `implementation-review` skill says.
- Before each fix round, run the finding checks of the
  `implementation-review` skill: one check for each new finding. Each
  check confirms its finding, finds its links, and checks its options. A
  finding that is not real or not in the scope is removed. The check
  corrects a wrong severity or category in place.
- Apply the fix rule. Make the final call on the outcome of each
  confirmed finding, with the merged options. Fix the findings with
  `Action: fix now`, with the option that each names. Record a follow-up
  item for each other finding and for each wider fix that you split off,
  as the `plans` skill says. Run the checks. Commit and push. Re-review
  once. Then stop the fix rounds and go on to step 6.

## 6. Pull request

- The implementation is complete when steps 1 to 5 are done. When the
  change has a plan, the implementation is complete only when the plan's
  other milestone TODOs are also ticked. A new plan has unticked
  milestone TODOs, so it is not complete. Open findings that wait for the
  user do not make the implementation incomplete.
- When the change has a plan, read "Deleting the plan" in the `plans`
  skill before you open the pull request. It says when the plan goes,
  when it stays, and the steps.
- Open the pull request when the implementation is complete, or when the
  user asks for it. Before that, report the branch. Write the title and
  the description with the `git-commit` skill. The description lists each
  follow-up item that the change adds, so that the user can bring one
  back into the branch before the merge.

## 7. CI

- After each push, run `scripts/ci-wait.sh` in the background on the
  pushed commit. It waits for the CI runs of the commit and prints their
  results. Go on with the work while it runs.
- When the script exits with a status other than 0, act as
  [references/ci.md](references/ci.md) says.
- Before the report, wait for the CI of the last push.

## 8. Report

Write the final message in Simplified Technical English, with the layout
and labels in the `decisions-and-findings` skill. Include:

- Each item that still needs the user's answer, also an item from an
  earlier message. Name it in the warning line at the top of the message.
  Give it in full when it is new or changed, or when the user asks.
  Otherwise give it in one line, as "Open items" in the
  `decisions-and-findings` skill says.
- What changed, the commit, and the branch or the pull request.
- The checks that ran and their results. Name any check that was skipped or
  could not run, and why.
- Each CI run of the last push and its result. Give the fix pull request
  or the follow-up item of each unrelated failure.
- The test cost of the change: each test that it adds or removes, with its
  run time, as the `testing` skill says.
- The fixed findings, the deferred findings and wider fixes with
  their follow-up items, and the findings that need a decision, each with
  a recommendation. Keep them in three lists.
- The number of open follow-up items in the repository.
- The follow-up items of the blocked wider fixes, one line per class.
- Problems outside the review scope, for a separate branch. An unrelated
  flaky test gives its name, failure text, rerun outcome, and suspected
  source.
- Open plan TODOs.

## 9. After the merge

When you learn that the pull request merged, remind the user of the open
follow-up items. Name the items that the change added. Give the number of
all open items, from the script in the `plans` skill. Start work on an
item only when the user asks for it. The one exception is a fix pull
request for an unrelated CI failure. It works on the item that records
the failure, as [references/ci.md](references/ci.md) says.

## Checklist

- [ ] Targeted tests pass at 100%.
- [ ] Each new asynchronous or browser test passed 10 of 10 runs.
- [ ] Smoke test done for new features.
- [ ] Complete gate passed once, or the blocker is explained.
- [ ] Docs, protocol docs, mockups, READMEs, and plan updated in the same
      change.
- [ ] Preservation audit clean: each deletion removes no functionality
      under the `git-commit` skill, or the user approved it.
- [ ] Committed with Conventional Commits and pushed; new files tracked.
- [ ] Post-push review run; `fix now` findings fixed; re-reviewed once.
- [ ] Each deferred or open finding has a follow-up item.
- [ ] Finding checks run before each fix round, one for each new finding.
      Removed findings named under **Checks**.
- [ ] Findings file of the branch up to date, with each check merged in.
- [ ] Options check run over the new plan decisions.
- [ ] When the change has a plan, the plan deleted or kept as the `plans`
      skill says. The pull request description gives its record and the
      follow-up items.
- [ ] Pull request opened once the implementation was complete or the user
      asked.
- [ ] CI of the last push watched to its end. Each failure fixed in the
      branch, given to a fix pull request, or reported.
- [ ] Final report in STE with fixed, deferred, and open findings, and the
      number of open follow-up items.
- [ ] Each item that still needs the user named in the warning line at
      the top, also an item from an earlier message. New and changed
      items given in full, the others in one line.
- [ ] After the merge, the user reminded of the open follow-up items.

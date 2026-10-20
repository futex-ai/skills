---
name: finish-work
description: Use before you say that work is complete or done, before you commit or push, when you decide which tests, checks, or gates to run, when a gate or a test suite fails or a run was partial, when you add a feature that needs a smoke test, and when the change that you finish is documentation-only or plan-only.
---

# Finish work

Work is complete only when every step below is done, in order. The commands
for each step come from the repository's `AGENTS.md` under `## Commands`. If
a step cannot run, say so, name the blocker, and list the checks that did
run.

## 1. During development

- Run only the tests that cover the change. Require a 100% pass rate for the
  tests that run.
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
  under the rules in the `deterministic-tests` skill.
- A flaky test that the diff adds or changes may be fixed without asking
  only under the flaky-test rule in the `deterministic-tests` skill.
- Documentation-only or plan-only changes, including initial plan creation,
  do not require the gate. Validate the changed Markdown and review the diff
  instead.

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

## 5. Review

- After the push, review the complete local diff against `origin/main` with
  the `implementation-review` skill. Review a branch that targets a primary
  branch against that branch instead. The review itself is read-only. Its
  findings stay in the diff unless the user explicitly asked for a wider
  review.
- Apply the review-fix rule: fix only the findings tagged `Auto-fix: yes`,
  with the option that each tag names, run the checks, commit, push,
  re-review once, then stop and report.

## 6. Report

Write the final message in Simplified Technical English, with the layout
and labels in the `decisions-and-findings` skill. Include:

- What changed, and the commit or PR.
- The checks that ran and their results. Name any check that was skipped or
  could not run, and why.
- Auto-fixed review findings, separately from the findings that need a
  decision, each with a recommendation.
- Follow-ups for the wider fixes that the review did not apply, one line
  per class.
- Problems outside the review scope, for a separate branch. An unrelated
  flaky test gives its name, failure text, rerun outcome, and suspected
  source.
- Open plan TODOs or follow-ups.

## Checklist

- [ ] Targeted tests pass at 100%.
- [ ] Smoke test done for new features.
- [ ] Complete gate passed once, or the blocker is explained.
- [ ] Docs, protocol docs, mockups, READMEs, and plan updated in the same
      change.
- [ ] Preservation audit clean: each deletion is dead code or approved.
- [ ] Committed with Conventional Commits and pushed; new files tracked.
- [ ] Post-push review run; `Auto-fix: yes` findings fixed; re-reviewed once.
- [ ] Final report in STE with fixed and open findings.

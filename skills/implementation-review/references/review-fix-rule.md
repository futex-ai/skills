# Review-fix rule

Rules for applying review findings after the post-push review reports.

## Auto-fix: yes

After the review reports, fix the findings tagged `Auto-fix: yes` without
waiting for the user. The reviewer may use that tag only when the finding
has one clear fix, for small or medium effort findings in these categories:

- Product bugs, including edge cases, races, and platform differences.
- Security issues.
- Docs or spec drift.
- Mockup mismatches that a protocol doc already settles.
- Flaky tests that the diff adds or changes, under the flaky-test rule in
  the `deterministic-tests` skill.
- Repository-rule violations such as file size, lint, and layout.

Effort grades: small is one change in one or two files with no new module,
dependency, migration, protocol section, or test file; medium is a few files
and may change tests in existing files; large adds a new module, dependency,
migration, protocol section, or mockup, crosses a package boundary, or
touches more than five files. Large findings always ask.

## Auto-fix: no

The reviewer tags a finding `Auto-fix: no` and the agent asks the user when
the finding needs a decision:

- More than one option has real trade-offs and the recommendation is not
  clearly best.
- The fix changes the meaning of a protocol contract, or decides which side
  of a mockup and product mismatch is right.
- The fix changes user-visible behaviour beyond what the contract says.
- The fix adds a new build error, rejection, gate, or stricter validation.
- A narrow fix and a better broader fix (a rule, test, lint, guard,
  abstraction, or architectural change) both exist, so the user chooses.
- The fix deletes, skips, or weakens a test or gate, or raises a time limit.
- The fix needs an audit exception, credentials, or infrastructure.
- The finding is a flaky test that the diff does not touch. Report it for a
  separate branch with its name, failure text, rerun outcome, and suspected
  source.
- The finding is a slow, custom, or low-value test, gate, lint, or check.
  Ask whether to fix or remove it, and state what it protects and how long
  it runs.

Findings about missing tests, performance, code structure, UX wording, and
process always wait for the user.

## Fix rounds

- Keep the review itself read-only.
- After it reports, fix the `Auto-fix: yes` findings, run the checks,
  commit, push, and re-run the review once on the fix.
- Fix any new `Auto-fix: yes` findings once more, then stop and report. Do
  not start a third fix round without the user.

## Reporting

- List the auto-fixed findings (number, severity, plain explanation, what
  changed, commit) separately from the findings that need a decision, each
  with a clear recommendation.
- Name the fixed finding in its commit message.
- Add each open finding as one line under the plan's review TODO so that it
  is not lost when the session ends.
- Keep the review report and any evidence under the git-ignored `.context/`
  directory, not in the repository.

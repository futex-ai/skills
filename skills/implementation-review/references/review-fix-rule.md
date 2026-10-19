# Review-fix rule

Rules for applying review findings after the post-push review reports.

## Effort

Effort grades one option, not the problem. The `decisions-and-findings`
skill gives the scale. It counts the code change only, and it gives file
and line bands for Small, Medium, and Large. The finding's effort is the
grade of the applied or recommended option. Small and Medium are within
the auto-fix cap. Large is above it.

## Blocked options

An option is blocked when:

- It is Large.
- It changes a requirement in a protocol doc without a recorded user
  decision, adds a requirement for new behaviour at the boundary, or
  decides which side of a mockup and product mismatch is right.
- It changes user-visible behaviour beyond what the contract says.
- It adds a new build error, rejection, gate, lint, or stricter validation.
  This holds for a wider fix too, whatever its effort. The always-on rules
  reserve that choice for the user.
- It deletes, skips, or weakens a test or gate, or raises a time limit.
- It needs an audit exception, credentials, or infrastructure.

## Auto-fix: yes

After the review reports, fix the findings tagged `Auto-fix: yes, apply
<letter>` without waiting for the user. The reviewer may use that tag only
when at least one option is not blocked, for findings in these categories:

- Product bugs, including edge cases, races, and platform differences.
- Security issues.
- Docs or spec drift: a doc that contradicts the changed code. Change the
  side that is wrong. A protocol doc is not right by default; see the
  `documentation` skill. The wider fix for the class is already in force,
  the `documentation` skill, so the reviewer proposes no other wider fix.
  The doc side changes without the user only when the plan records the
  user's decision for the behaviour change, or when the doc content is
  implementation detail or history that moves to its home.
- Mockup mismatches that a protocol doc already settles.
- Flaky tests that the diff adds or changes, under the flaky-test rule in
  the `deterministic-tests` skill.
- Repository-rule violations such as file size, lint, and layout.

The letter names the widest option that is not blocked: the wider fix when
it is not blocked, otherwise the direct fix. So a Small or Medium wider fix
is applied before a direct fix, and a blocked wider fix does not block the
tag.

## Auto-fix: no

The reviewer tags a finding `Auto-fix: no` and the agent asks the user
when:

- Every option is blocked.
- The best option on the merits is blocked and is not a wider fix. The
  reviewer recommends that option, and the user decides.
- More than one option has real trade-offs and the recommendation is not
  clearly best.
- The finding is a slow, custom, or low-value test, gate, lint, or check.
  Ask whether to fix or remove it, and state what it protects and how long
  it runs.
- The finding is about missing tests, performance, code structure, UX
  wording, or process.

## Wider fixes and follow-ups

- The reviewer proposes a wider fix for every finding and grades it like
  any other option. When the wider fix for the class is already in force,
  such as the `documentation` skill for docs drift or an existing lint, the
  reviewer says so and proposes no other wider fix.
- A blocked wider fix is not applied in the fix round. The direct fix is
  applied when it is not blocked. When the finding is fixed, the agent
  lists the blocked wider fix as a follow-up: one line per class under
  **Open** in the final message and under the plan's review TODO. The line
  gives the wider fix, its effort, the finding numbers it covers, and the
  previous examples. When the finding stays open, its wider fix stays one
  of its options, and it gets no follow-up line.
- Count the occurrences of the class: the findings of this review that
  share the wider fix, plus the previous examples that the reviewer cited.
  When the count is two or more, the agent raises the wider fix as a
  numbered decision in the decision layout instead of a follow-up line.
- If an applied option grows past Medium during the fix, revert it. Apply
  the next smaller option that is not blocked, or leave the finding open
  and report it.

## Outside the scope

The scope is the diff, unless the user explicitly asked for a wider review.
The reviewer lists each problem outside the scope under `Outside the scope`,
one line each, without a number or the finding layout. These problems are
not findings. Do not fix them in this branch, so that one fix in a separate
branch reaches every open branch. An unrelated flaky test is such a problem.
Its line gives the test name, the failure text, the rerun outcome, and the
suspected source, as the `deterministic-tests` skill requires.

## Fix rounds

- Keep the review itself read-only.
- After it reports, apply the option that each `Auto-fix: yes` tag names,
  run the checks, commit, push, and re-run the review once on the fix.
- Fix any new `Auto-fix: yes` findings once more, then stop and report. Do
  not start a third fix round without the user.

## Reporting

- List the auto-fixed findings (number, severity, plain explanation, the
  applied option, what changed, commit) separately from the findings that
  need a decision, each with a clear recommendation. Order both lists by
  severity, High first. Use the `decisions-and-findings` skill.
- Name the fixed finding in its commit message.
- Add each open finding as one line under the plan's review TODO so that it
  is not lost when the session ends. Use the shape that the `plans` skill
  gives.
- List each follow-up under **Open** in the final message, one line per
  class. When a plan exists, add each one as one line under the plan's
  review TODO too.
- List the `Outside the scope` problems under **Open** in the final message,
  for a separate branch. When a plan exists, add each one as one line under
  the plan's review TODO too.
- Keep the review report and any evidence under the git-ignored `.context/`
  directory, not in the repository.

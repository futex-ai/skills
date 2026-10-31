# Review-fix rule

Rules for the findings of the post-push review: which findings the agent
may fix without the user, when it fixes them, and how it records the rest.

## Outcomes

Each finding ends with one `Action` line:

- `Action: fix now, apply <letter>`. The agent applies the option in this
  branch, before the merge.
- `Action: fix after merge, apply <letter>, because <reason>`. The agent
  records a follow-up item. A later branch applies the option without the
  user.
- `Action: ask the user, because <reason>`. The finding waits for the
  user. The agent records a follow-up item so that the finding is not lost.
  The reason gives the case in plain words, as "Ask the user" says.
- `Action: fix now, apply <letter>, and fix after merge, apply <letter>,
  because <reason>`. The agent splits the finding. It applies the direct
  fix now and records the wider fix as a follow-up item. The section
  "Split a finding" says when.

The reviewer proposes the outcome. The working agent makes the final call,
because it knows the purpose of the branch. When the working agent changes
the proposed outcome, it gives one sentence of reason.

## Effort

Effort grades one option, not the problem. The `decisions-and-findings`
skill gives the scale. It counts the code change only, and it gives file
and line bands for Small, Medium, and Large. The finding's effort is the
grade of the applied or recommended option.

## Blocked options

An option is blocked when:

- It changes a requirement in a protocol doc without a recorded user
  decision, adds a requirement for new behaviour at the boundary, or
  decides which side of a mockup and product mismatch is right.
- It changes user-visible behaviour beyond what the contract says.
- It adds a new build error, rejection, gate, lint, or stricter validation.
  This holds for a wider fix too, whatever its effort. The always-on rules
  reserve that choice for the user.
- It adds a test for the class: a test that catches every case of a
  defect class. A property test that the review proposes as a wider fix
  is one. The regression test for the defect itself is not blocked.
- It deletes or overrides functionality on `origin/main`. Functionality
  is everything on `origin/main` that is not dead code under the
  predicate in the `git-commit` skill. It includes live code, its tests,
  an API, a doc, a mockup, a plan, a migration, and schema. A deletion of
  dead code is not blocked. The plan of the change and a follow-up item
  that the change fixes are not functionality.
- It deletes, skips, or weakens a test of live code or a gate, or raises
  a time limit. A removal under the removal rule of the `testing` skill
  is not blocked.
- It needs credentials or infrastructure.

## Fixes without the user

The decision test in the `decisions-and-findings` skill decides whether a
finding waits for the user. The outcome can be `fix now` or
`fix after merge` only when no condition of the test holds. This rule lets
the agent fix a finding without the user only when the finding is in one
of these categories:

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
- Dead code: code that the product never runs, under the predicate in
  the `git-commit` skill. The reviewer checks each condition with a
  search and cites the searches in the finding. The option deletes the
  dead code with the steps under "When you delete dead code" in the
  `git-commit` skill. Code that the product runs rarely, such as an error
  path or a fallback, is functionality and waits for the user.
- Tests that the removal rule of the `testing` skill covers: a duplicate
  of a named test, a test of removed behaviour, or a test of something
  that never gets a test. The option removes the test with the steps and
  the proof that the rule requires.
- Test findings: a missing test, a weak test, a slow test, or a test in
  the wrong file or group. The reviewer gives the finding the category
  test. A fix that changes a test removes no assertion and loosens none.
  A removal follows the bullet above.
- Repository-rule violations such as file size, lint, and layout.
- Copy defects whose fix keeps the meaning: user-facing text that has a
  typo or breaks a rule under `## Copy` in the `product-ui` skill. The
  reviewer gives the finding the category UX wording, not repository rule.
  The fix keeps the meaning when it adds no fact or action and removes no
  fact or action that the end user needs. When no protocol doc states the
  text, a fix that keeps the meaning stays within the contract. The direct
  fix changes only the words that carry the defect. When the meaning is in
  doubt, the outcome is `ask the user`.

The letter names the best-ranked option that is not blocked: a structural
wider fix, then a detection wider fix, then the direct fix. The ranking is
under "Wider fixes and follow-ups". So a wider fix ranks before a direct
fix, and a blocked wider fix does not block the fix. The agent can still
split the finding and apply the wider fix after the merge.

## Fix now or after merge

When the agent may fix a finding, it decides when. The outcome is
`fix now` when one of these holds:

- The severity is High.
- The fix gets much harder after the merge. Examples are a migration, a
  stored data format, or a public API or message that the diff adds.
- The problem breaks a gate or a test, or the diff adds or changes a
  flaky test.
- A doc contradicts the changed code.

Otherwise, the outcome is `fix now` when the fix is Small and stays in the
files that the diff changes. A follow-up item for such a fix costs more
than the fix.

A product bug with the likelihood Rare gets `fix now` only when its
severity is High or its fix gets much harder after the merge. Otherwise
its outcome is `fix after merge`, also when the fix is Small. Its fix adds
code for a case that seldom happens, and the re-review reads that code
too. The `decisions-and-findings` skill gives the likelihood scale.

For every other finding, the agent decides. It weighs these questions:

- Does the fix serve the purpose of the branch?
- Does the fix reach files or areas outside the diff?
- Do other open branches need the same fix? Then one branch after the
  merge reaches all of them.
- Does the end user meet the problem before a later branch can fix it?

Give each `fix after merge` outcome one sentence of reason. The pull
request description lists each one, so that the user can bring it back
into the branch before the merge.

## Split a finding

When the named option is a wider fix and the direct fix is not blocked,
the agent can split the finding. It applies the direct fix now, and it
records the wider fix as a follow-up item with `fix after merge`. A later
branch applies the wider fix without the user.

The agent decides. It asks the questions of the section above about the
wider fix. A split fits when the wider fix does not serve the purpose of
the branch, reaches files or areas outside the diff, or serves other open
branches too. A Small wider fix that stays in the files of the diff goes in
with the direct fix. Give each split one sentence of reason.

## Ask the user

The outcome is `ask the user` when a condition of the decision test
holds. For a finding, a condition holds in each of these cases:

- Every option is blocked.
- The best option on the merits is blocked and is not a wider fix. The
  reviewer recommends that option, and the user decides.
- More than one option has real trade-offs, and the recommendation is not
  clearly best.
- The finding is outside the categories above.
- The finding is about a slow, custom, or low-value gate, lint, or check,
  or about the removal of a test that the removal rule of the `testing`
  skill does not cover. Ask whether to fix or remove it, and state what it
  protects and how long it runs.
- The finding is about performance, code structure, or process.
- The finding is about any other UX wording. Examples are a choice of
  tone or voice that no copy rule settles, and a choice between two
  correct texts.

The reason in the `Action` line gives the case in plain words, with its
evidence. It does not cite a condition by a number. Example: "ask the
user, because no option is clearly best until a reproduction names the
source."

## Wider fixes and follow-ups

- The reviewer proposes a wider fix for every finding and grades it like
  any other option. When the wider fix for the class is already in force,
  such as the `documentation` skill for docs drift or an existing lint, the
  reviewer says so and proposes no other wider fix.
- A test of something that the `testing` skill says never gets a test,
  such as doc prose or a one-time proof, is not a wider fix.
- Rank wider fixes by how they prevent the class. A structural fix removes
  the wrong case: a helper or an abstraction that every call site uses, a
  default that is right, a marker that shared code honours, or a type that
  cannot hold the wrong value. A detection fix catches the wrong case: a
  test for the class, a lint, or a guard. Prefer a structural fix. Propose
  a detection fix as the wider fix only when you find no structural fix. A
  structural fix needs no guard to maintain and no test for the class. The
  regression test for the bug itself still accompanies the fix, under the
  testing rules.
- Example: a modal focused the first tabbable element, a helper icon
  button, because no autofocus target was given. A guard that requires a
  target is a detection fix. A marker that excludes helper icons from
  autofocus is a structural fix: the case cannot recur, and nothing
  expires.
- A blocked wider fix is not applied in the fix round. The direct fix is
  applied when it is not blocked. When the finding is fixed, the agent
  records the blocked wider fix as one follow-up item per class. The item
  gives the wider fix, its effort, the problem of each finding that it
  covers, and the previous examples. When the finding stays open, its
  wider fix stays one of its options, and it gets no item of its own.
- A wider fix that the agent splits off gets the same item, one per class,
  with `fix after merge`. A later branch applies it without the user.
- Count the occurrences of the class of a blocked wider fix: the findings
  of this review that share the wider fix, plus the previous examples that
  the reviewer cited. When the count is two or more, the agent also raises
  the wider fix as a numbered item with the source Review.

## Outside the scope

The scope is the diff, unless the user explicitly asked for a wider review.
The reviewer lists each problem outside the scope under `Outside the scope`,
one line each, without a number or the item layout. These problems are
not findings. Do not fix them in this branch, so that one fix in a separate
branch reaches every open branch. Record each one as a follow-up item, in
the full layout that the `plans` skill gives. An unrelated flaky test is
such a problem. Its line gives the test name, the failure text, the rerun
outcome, and the suspected source, as the `deterministic-tests` skill
requires.

## Fix rounds

- Keep the review itself read-only.
- Before each fix round, run one finding check for each new finding, as
  the `implementation-review` skill says. Each check confirms its finding,
  finds its links to the other findings, and checks its options. A finding
  that is not real or not in the scope is removed. The check corrects a
  wrong severity or category in place. A real problem outside the scope
  joins the `Outside the scope` list. The fix round waits for every check
  and applies confirmed findings only.
- After every check reports, merge the reports into the findings file.
  Then make the final call on each outcome, with the merged options. A
  check can change the letter of a finding that the agent may fix. It
  does not turn an open finding into a fix, and it does not change an
  `Action` line by itself.
- Apply the option that each confirmed `fix now` line names. Record a
  follow-up item for each `fix after merge` finding, each `ask the user`
  finding, each blocked or split-off wider fix of a fixed finding, and
  each problem outside the scope. The `plans` skill gives the layout of an
  item. Run the checks, commit, and push. Then re-run the review once on
  the fix.
- Run the finding checks on the new findings, and again on each open
  finding whose code a fix changed. Fix any confirmed new `fix now`
  findings once more, and record the other new findings as follow-up
  items. Then stop. The `finish-work` skill gives the next steps: the pull
  request and the report. Do not start a third fix round without the
  user.
- When the user answers an `ask the user` finding and the branch applies
  the answer, delete its follow-up item in the same commit. Record the
  answer and its date in the findings file.

## Reporting

- Keep three lists: the fixed findings, the deferred findings, and the
  findings that need a decision. Order each list by severity, High first.
  Use the `decisions-and-findings` skill.
  - For a fixed finding, give its number, its severity, a plain
    explanation, the applied option, what changed, and the commit.
  - For a deferred finding or a split-off wider fix, give the finding
    number, its severity, the reason, and the follow-up item.
  - For a finding that needs a decision, give a clear recommendation.
- Name the fixed finding in its commit message.
- Give each open finding with its finding check merged in. Its new
  options keep their letters. When the recommendations differ, give both.
- Name each finding that a finding check removed in one line under
  **Checks**. Give its number, its title, and the check that failed.
- List under **Open** the follow-up items of the blocked wider fixes and of
  the problems outside the scope, one line each.
- Build the three lists from the findings file of the branch.
- Keep the findings file, the review reports, and any evidence under the
  git-ignored `.context/` directory, not in the repository.

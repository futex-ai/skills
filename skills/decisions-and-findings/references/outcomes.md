# Outcomes

Every item ends with an outcome: the item waits for the user, or the agent
acts on it without the user. This file holds the two outcome rules:

- The decision test says when an item waits for the user. It applies in
  the same way to every item: a finding or a question, from design, from
  implementation, or from a review.
- The fix rule says how the agent fixes a finding that does not wait:
  which option it applies, and when.

The working agent pastes this file into the prompt of a fresh reviewer, as
the `implementation-review` skill says. So the reviewer and the working
agent read the same text.

## The decision test

Apply this test to each finding and to each question that you raise. Look
at the option that you recommend. For a finding, the fix rule below says
which option to recommend. The item is a decision for the user only when
one of these conditions holds:

- The recommended option changes a requirement or a decision in force,
  and no recorded user decision covers the change.
- The recommended option adds behaviour at a boundary that no
  requirement covers.
- The recommended option is blocked. The section "Blocked options" gives
  the list.
- Two or more options have real trade-offs, and no option is clearly
  best. This also holds when the options of two items conflict and no
  rule settles which one wins. It holds when a fix depends on the answer
  to an open item, because no option is clearly best before the answer.
- The user asked you to bring this choice to them.

A detail that an existing requirement settles is not a gap, also when the
requirement does not spell the detail out. An option that drops the
requirement does not make the item a decision when you do not recommend
that option.

A behaviour at the boundary that a change adds and no requirement covers
is a spec gap. Report it as one finding. The finding waits for the user,
because the user reviews each new requirement.

When no condition holds, apply the recommended option without the user:

- A finding gets `fix now` or `fix after merge`. The fix rule says which
  one, and when to split the finding.
- A question is a design call. Record the call, its reason, and the
  date in the plan, in the design of the change. When the change has no
  plan, record it in the commit or the pull request description. Do not
  ask the user. Give each design call one line in the final report.

Three signs that an item fails the test:

- The recommendation says that the option costs nothing.
- The severity is Low, and the impact is only that the work waits for the
  answer.
- The **Action** reason says only that the item is a decision.

## Blocked options

An option is blocked when:

- It changes a requirement in a protocol doc without a recorded user
  decision, or adds a requirement for new behaviour at the boundary.
- It changes a mockup to match the code, and the `mockups` skill does not
  call for that change.
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

## The fix rule

The sections below are the fix rule. The agent that reports a finding
proposes its outcome. That agent is the reviewer, or the agent that
builds the change. The working agent makes the final call, because it
knows the purpose of the branch. When the working agent changes the
proposed outcome, it gives one sentence of reason.

### The Action line

Each finding ends with one `Action` line:

- `Action: fix now, apply <letter>`. The agent applies the option in this
  branch, before the merge.
- `Action: fix after merge, apply <letter>, because <reason>`. The agent
  records a follow-up item. A later branch applies the option without the
  user.
- `Action: ask the user, because <reason>`. The finding waits for the
  user. The agent records a follow-up item so that the finding is not lost.
- `Action: fix now, apply <letter>, and fix after merge, apply <letter>,
  because <reason>`. The agent splits the finding. It applies the direct
  fix now and records the wider fix as a follow-up item. The section
  "Split a finding" says when.

The reason of `ask the user` says in plain words which condition of the
decision test holds, with its evidence. It does not cite a condition by a
number. Example: "ask the user, because no option is clearly best until a
reproduction names the source."

### Rules for some kinds of finding

These rules apply the decision test and the fix to some kinds of finding.
A kind that is not in this list has no rule of its own.

- Docs or spec drift: a doc that contradicts the changed code. Change the
  side that is wrong. A protocol doc wins over the code by default, as the
  `documentation` skill says. The wider fix for the class is already in
  force, the `documentation` skill, so propose no other wider fix. The
  doc side changes without the user only in these cases:
  - The diff changes behaviour that a requirement states, and the plan
    records the user's decision for that change. The doc update is the
    named option. Without a recorded decision, the doc wins, and the
    finding is a product bug in the code. When the doc is wrong, or worse
    than the code, recommend the doc update. The finding then waits for
    the user, because the user decides each requirement change.
  - The doc names source files, functions, or internal mechanics, or it
    records history. The fix moves that content to its home: the crate
    README for entry points, the plan for history, and the code for
    mechanics. The move is the named option.
- Mockup mismatches: a mockup that differs from a protocol doc or from the
  code. The protocol doc wins over the mockup, and the mockup wins over
  the code. The section "When a protocol doc, a mockup, and the code
  disagree" in the `mockups` skill gives the cases. A fix that the section
  calls for needs no user decision. A protocol doc changes only under the
  docs or spec drift rule above. When the section says to ask the user,
  the finding waits for the user. When the higher side is wrong, or worse
  than the lower side, recommend its change. The finding then waits for
  the user. The wider fix for the class is already in force, that
  section, so propose no other wider fix.
- Flaky tests that the diff adds or changes, under the flaky-test rule of
  the `testing` skill.
- Dead code: code that the product never runs, under the predicate in the
  `git-commit` skill. Check each condition with a search, and cite the
  searches in the finding. The option deletes the dead code with the steps
  under "When you delete dead code" in the `git-commit` skill. Code that
  the product runs rarely, such as an error path or a fallback, is
  functionality. When a condition is in doubt, the code is functionality,
  as the `git-commit` skill says.
- Tests that the removal rule of the `testing` skill covers: a duplicate
  of a named test, a test of removed behaviour, or a test of something
  that never gets a test. The option removes the test with the steps and
  the proof that the rule requires.
- Test findings: a missing test, a weak test, a slow test, or a test in
  the wrong file or group. Give the finding the category test. A fix that
  changes a test removes no assertion and loosens none. A removal follows
  the bullet above.
- Gates: a slow, custom, or low-value gate, lint, or check is not a test
  finding. The `testing` skill says how to fix it.
- UX wording: user-facing text. A copy defect is text that has a typo or
  breaks a rule under `## Copy` in the `product-ui` skill. Give a copy
  defect the category UX wording, not repository rule. A fix keeps the
  meaning when it adds no fact or action and removes no fact or action
  that the end user needs. When no protocol doc states the text, a fix
  that keeps the meaning stays within the contract. The direct fix of a
  copy defect changes only the words that carry the defect. When the
  meaning is in doubt, treat the fix as a change of user-visible behaviour
  beyond the contract. A choice of tone or voice that no copy rule
  settles, or a choice between two correct texts, has no clearly best
  option.

### The option to apply

The letter names the best-ranked option that is not blocked: a structural
wider fix, then a detection wider fix, then the direct fix. So a wider fix
ranks before a direct fix, and a blocked wider fix does not block the fix.
A blocked wider fix is not applied in the fix round. The direct fix is
applied when it is not blocked. The agent can still split the finding and
apply the wider fix after the merge.

- Rank wider fixes by how they prevent the class. A structural fix
  removes the wrong case: a helper or an abstraction that every call site
  uses, a default that is right, a marker that shared code honours, or a
  type that cannot hold the wrong value. A detection fix catches the
  wrong case: a test for the class, a lint, or a guard. A structural fix
  needs no guard to maintain and no test for the class. The regression
  test for the bug itself still accompanies the fix, under the testing
  rules.
- Example: a modal focused the first tabbable element, a helper icon
  button, because no autofocus target was given. A guard that requires a
  target is a detection fix. A marker that excludes helper icons from
  autofocus is a structural fix: the case cannot recur, and nothing
  expires.
- A test of something that the `testing` skill says never gets a test,
  such as doc prose or a one-time proof, is not a wider fix.

When the best option on the merits is blocked and is not a wider fix,
recommend that option, so the finding waits for the user.

### Fix now or after merge

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
than the fix. The effort of a finding is the grade of its applied or
recommended option, under the effort scale of the `decisions-and-findings`
skill.

A product bug with the likelihood Rare gets `fix now` only when its
severity is High or its fix gets much harder after the merge. Otherwise
its outcome is `fix after merge`, also when the fix is Small. Its fix adds
code for a case that seldom happens, and the re-review reads that code
too. The `decisions-and-findings` skill gives the likelihood scale.

For every other finding, the agent decides. It weighs these questions:

- Does the fix serve the purpose of the branch? The plan of the change,
  when it has one, gives the purpose.
- Does the fix reach files or areas outside the diff?
- Do other open branches need the same fix? Then one branch after the
  merge reaches all of them.
- Does the end user meet the problem before a later branch can fix it?

Give each `fix after merge` outcome one sentence of reason. The pull
request description lists each one, so that the user can bring it back
into the branch before the merge.

### Split a finding

When the named option is a wider fix and the direct fix is not blocked,
the agent can split the finding. It applies the direct fix now, and it
records the wider fix as a follow-up item with `fix after merge`. A later
branch applies the wider fix without the user.

The agent decides. It asks the questions of the section above about the
wider fix. A split fits when the wider fix does not serve the purpose of
the branch, reaches files or areas outside the diff, or serves other open
branches too. A Small wider fix that stays in the files of the diff goes in
with the direct fix. Give each split one sentence of reason.

# Review prompt

Give this prompt to the reviewer. Replace `<review focus>` with the
`## Review focus` list from the repository's `AGENTS.md`, or delete that
sentence when the repository has none. Replace `<first number>` with the
first free finding number of the branch. Replace `<review folder>` with
the review folder of the branch. The findings file reference of this
skill gives both.

The scope of the prompt is the diff. When the user explicitly asks for a
review outside the changes, for example of the whole repository or of a
named area, replace the first paragraph of `## Scope` with the scope that
the user named. Do not widen the scope for any other reason.

When the branch targets a primary branch instead of `main`, replace
`origin/main` with that branch throughout. The `delegating` skill
describes the primary branch.

---

You are reviewing local changes in this repository.

Review the local diff against `origin/main`. You may inspect the repository
read-only for context. Focus on concrete bugs, security issues, missing
tests, weak tests, docs that contradict the changed code, generated
artifact drift, and implementation risks in the scope below. A weak test
cannot fail, was weakened or special-cased to pass, is over-mocked, or
uses a hand-written fake store. A missing-test finding names the
requirement or the defect that no test covers. It also names a code change
that no existing test catches. Pay particular attention to
<review focus> in that scope. Do not treat speculative or purely theoretical
concerns as findings. Do not modify files or automatically fix findings.

## Scope

The scope is the diff: each changed or added hunk, and the code outside the
diff whose behaviour the diff changes. That code includes a caller of a
changed function, a test that covers changed code, a doc that describes
changed behaviour, and a generated artifact of a changed source. A finding
must anchor to the scope.

A problem outside the scope is not a finding. Do not number it, and do not
give it the item layout. Put it in one list under the heading
`Outside the scope` at the end of the report. Give each problem one line:
the file path and one sentence. Nobody fixes these problems in this
branch. The working agent records each one as a follow-up item. A flaky
test that the diff does not touch belongs in this list, with its name,
failure text, rerun outcome, and suspected source.

The context reads, the review focus, and the previous-examples search serve
the findings in scope. They are not a search for new findings.

Start by collecting compact summaries so that large diffs fit in context:

```bash
git status --short
git diff --stat origin/main...
git diff --name-status origin/main...
git diff --staged --stat --
git diff --staged --name-status --
git diff --stat --
git diff --name-status --
git ls-files --others --exclude-standard
```

Inspect changed files and focused patches directly before raising findings:

```bash
git diff origin/main... -- <path>
git diff --staged -- <path>
git diff -- <path>
sed -n '<start>,<end>p' <path>
```

Look for previous examples of a finding's class. This search is best
effort. Use a hit only as an example. A hit is not a new finding. Do not
read `<review folder>`. It holds the earlier rounds of this branch, and
your review must stay independent of them:

```bash
git log --oneline origin/main -- <path>
git log --oneline -i --grep='<keyword>' origin/main
grep -rni '<keyword>' plans/ .context/ 2>/dev/null | grep -v '^<review folder>/'
```

Return the numbered findings first and the `Outside the scope` list last.
Order the findings by severity, High first, then Medium, then Low, and
number them in that order, from <first number>. Use the item layout in the
`decisions-and-findings` skill, with the source Review. For every finding:

- Give it a severity: the harm when the problem happens, not how often it
  happens. High: wrong output, lost data, a security problem, or blocked
  work. Medium: a visible defect, or a spec gap with a workaround. Low:
  wording, style, or a defect that costs the user little.
- For a product bug, give a likelihood. Common: normal use meets it, also
  when only now and then. Rare: normal use does not meet it. Only an
  unusual input, timing, platform, or setup does. A problem that an
  attacker can cause is a security problem, not a rare product bug.
- Give it a category. The categories are product bug, security, docs or
  spec, mockup, repository rule, test, performance, code structure, dead
  code, UX wording, and process.
- Include the relevant file path and line reference when possible.
- Give the terms: each project term that the finding uses, with one
  sentence that explains it. The `decisions-and-findings` skill says what
  a term is, when to leave the slot out, and how many entries a list
  holds.
- Give the background: enough codebase and feature context for a reader
  with no prior knowledge.
- State the problem: what is wrong, in plain words and defined terms.
- State the impact of making no change.
- Write the root question of the finding in the words of the goal, not
  of the current mechanism. Then give solution options labelled A, B, and
  so on, from the smallest effort to the largest. Widen and narrow them
  with the options rule of the `decisions-and-findings` skill: at least
  three distinct approaches, or one sentence that says why fewer are
  real, its two questions, and a **Left out** line with the reason for
  each approach that you leave out. Always consider a wider
  fix: a rule, test, lint, guard, abstraction, or architectural change
  that prevents the class of issue.
  Prefer a structural fix that removes the wrong case, such as a helper or
  an abstraction that every call site uses, a default that is right, a
  marker that shared code honours, or a type that cannot hold the wrong
  value. Propose a detection fix that catches the case, such as a test for
  the class, a lint, or a guard, only when you find no structural fix. For
  example, when a modal focuses a helper icon button because no autofocus
  target was given, a guard that requires a target detects the case, and a
  marker that excludes helper icons from autofocus removes it. Do not
  propose a test of something that the `testing` skill says never gets a
  test, such as doc prose, workflow literals, or a one-time proof. Give the
  wider fix its own lettered option. Look for previous examples of
  the class in the commit history, under `plans/`, and in earlier review
  reports under `.context/`. Cite the examples you find. Propose the wider
  fix even when you find none. When the wider fix for the class is already
  in force, such as a skill rule or an existing lint, say so and propose no
  other wider fix. When two or more findings share one wider fix, say so in
  each of them.
- Give each option an effort grade. Effort grades the code change of one
  option, not the problem. Count product code, scripts, configuration, and
  infrastructure files. Do not count tests, README files, protocol docs,
  plans, or mockup output, because the repository rules require them with
  each code change. Small: two code files or fewer, 30 code lines or fewer,
  and no new code or test file. Medium: five code files or fewer in one
  package, and 150 code lines or fewer. A new test file or a new helper
  module in the same package is Medium. Large: every option that is not
  Small or Medium. A new dependency, a migration, a change on both sides
  of the backend and frontend boundary, a new mockup, or a new protocol
  section is Large whatever its size. The finding's effort is the grade of
  the recommended option.
- Recommend one option and say which option best protects the codebase.
  For a finding that the agent may fix without the user, recommend the
  option that the `Action` line names.
- End the finding with an `Action` line that proposes one outcome:
  `fix now, apply <letter>`, `fix after merge, apply <letter>, because …`,
  or `ask the user, because …`. A finding with a wider fix can get a split
  instead, as described below. The working agent makes the final call. The decision test
  in the `decisions-and-findings` skill decides whether the finding waits
  for the user.

An option is blocked when:

- It changes a requirement in a protocol doc without a recorded user
  decision, or adds a requirement for new behaviour at the boundary.
- It changes a mockup to match the code without a recorded user decision.
- It changes user-visible behaviour beyond the contract.
- It adds a new build error, rejection, gate, lint, or stricter validation.
  This holds for a wider fix too, whatever its effort.
- It adds a test for the class: a test that catches every case of a
  defect class. The regression test for the defect itself is not blocked.
- It deletes or overrides functionality on `origin/main`. Functionality
  is everything on `origin/main` that is not dead code under the
  conditions below. It includes live code, its tests, an API, a doc, a
  mockup, a plan, a migration, and schema. A deletion of dead code is not
  blocked. The plan of the change and a follow-up item that the change
  fixes are not functionality.
- It deletes, skips, or weakens a test of live code or a gate, or raises
  a time limit. A removal under the removal rule of the `testing` skill
  is not blocked.
- It needs credentials or infrastructure.

`fix now` and `fix after merge` are allowed only when no condition of the
decision test holds. For a finding, condition 6 holds unless the finding
is about:

- a product bug, including edge cases, races, and platform differences
- a security issue
- docs or spec drift
- a mockup mismatch that the spec order below settles
- a flaky test that the diff adds or changes
- dead code
- a test that the removal rule of the `testing` skill covers
- a repository-rule violation such as file size, lint, or layout
- a copy defect whose fix keeps the meaning

The letter names the best-ranked option that is not blocked: a structural
wider fix, then a detection wider fix, then the direct fix. A blocked wider
fix does not block the fix. For a flaky test that the diff adds or
changes, name the nondeterminism source and the deterministic fix. The
deterministic fixes are a fake clock, event order, captured inputs,
operation counts, an explicit readiness signal, or isolated state. Require
the fixer to reproduce the flake and record pass counts before and after.

Propose `fix now` when one of these holds:

- The severity is High.
- The fix gets much harder after the merge. Examples are a migration, a
  stored data format, or a public API or message that the diff adds.
- The problem breaks a gate or a test, or the diff adds or changes a flaky
  test.
- A doc contradicts the changed code.

Otherwise, propose `fix now` when the fix is Small and stays in the files
that the diff changes. For a product bug with the likelihood Rare, propose
`fix now` only when its severity is High or its fix gets much harder after
the merge. Otherwise propose `fix after merge`, also when the fix is Small.
For every other finding, weigh the purpose of the branch, the files that
the fix reaches outside the diff, and whether the end user meets the
problem before a later branch can fix it. Read the plan of the change,
when it has one, for its purpose. Give each `fix after merge` proposal one
sentence of reason.

When the named option is a wider fix and the direct fix is not blocked,
you can propose a split: the direct fix now, and the wider fix after the
merge. A split fits when the wider fix does not serve the purpose of the
branch, reaches files or areas outside the diff, or serves other open
branches too. Keep a Small wider fix that stays in the files of the diff
with the direct fix. Write a split with the direct fix first:
`fix now, apply <letter>, and fix after merge, apply <letter>, because …`.

Dead code is code that the product never runs. Code is dead only when all
of these hold:

- No product code, test of live code, script, configuration, build file,
  or generated artifact references it.
- No route table, registry, plugin loader, file-name convention, string
  key, dynamic import, or reflection names it.
- No consumer outside the code reaches it. A command, a script, a
  migration, or an export of a published package is an entry point, not
  dead code.
- Nothing keeps it on purpose: no dead-code annotation, feature flag, open
  plan TODO, or protocol doc.

Test code is not product code. A helper, a fixture, or a mock that a test
of live code uses is functionality. Check each condition with a search of
the repository. Cite the searches in the finding. The option deletes the
code, the tests that cover only it, and each item that the deletion
leaves unused and that meets the conditions. It moves a test that reaches
live behaviour through the dead code to the live path, with every
assertion kept.

Code that the product runs rarely is functionality: an error path, a
fallback, or the off branch of a feature flag. Its deletion is blocked.
When a condition is in doubt, give the finding the category code
structure and propose `ask the user`.

A copy defect is user-facing text that has a typo or breaks a rule under
`## Copy` in the `product-ui` skill. Give it the category UX wording, not
repository rule. The fix keeps the meaning when it adds no fact or action
and removes no fact or action that the end user needs. When no protocol
doc states the text, a fix that keeps the meaning stays within the
contract. The direct fix changes only the words that carry the defect.
When the meaning is in doubt, propose `ask the user`.

Propose `ask the user` when a condition of the decision test holds. For a
finding, the conditions work as follows:

- Condition 3 holds when every option is blocked.
- Condition 3 also holds when the best option on the merits is blocked and
  is not a wider fix. Recommend that option, so that the user decides.
- Condition 4 holds when more than one option has real trade-offs and no
  option is clearly best.
- Condition 6 holds for a finding outside the list above. It also holds
  for a slow, custom, or low-value test, gate, lint, or check in the scope
  that the removal rule of the `testing` skill does not cover. Ask whether
  to fix it or remove it, and state what it protects and how long it runs.
- Condition 6 holds for a finding about missing tests, performance, code
  structure, or process.
- Condition 6 holds for any other UX wording. Examples are a choice of
  tone or voice that no copy rule settles, and a choice between two
  correct texts.

Protocol docs hold the requirements and the decisions in force for an area:
observable behaviour at a boundary, and the reason for each choice. They do
not describe how the code works. Do not treat them as fixed rules. When the
code and a protocol doc disagree, the doc wins by default. Still judge the
doc on its merits. Apply these rules to a docs or spec finding:

- Docs or spec drift is a doc that contradicts the changed code. A doc that
  is silent on how the code works is not a finding. Do not ask for a doc to
  be clarified or enhanced.
- The wider fix for the class is already in force, the `documentation`
  skill. Do not propose another wider fix for it.
- When the code breaks a requirement and the diff did not intend a
  behaviour change, the finding is a product bug in the code.
- When the diff changes behaviour that a requirement states, and the plan
  records the user's decision for that change, the fix updates the doc.
  The agent may apply it without the user, with the doc update as the
  named option. Without a recorded decision, the doc wins, and the finding
  is a product bug in the code. When the doc is wrong, or worse than the
  code, recommend the doc update and propose `ask the user`, because the
  user decides each requirement change.
- A behaviour at the boundary that the diff adds and no requirement covers
  is a spec gap. Report it as one finding with `ask the user`, because the
  user reviews each new requirement. A detail that an existing requirement
  settles is not a gap, also when the requirement does not spell the
  detail out.
- When a protocol doc in the scope names source files, functions, or
  internal mechanics, or records history, the fix moves that content to
  its home: the crate README for entry points, the plan for history, the
  code for mechanics. The agent may apply it without the user, with the
  move as the named option.
- Do not drop an option, rank it lower, or recommend a different option
  only because it conflicts with a protocol doc. Include the doc update in
  that option and in its effort grade, and recommend the option when it is
  the best one.

Mockups are part of the spec too. The spec order is the protocol doc, then
the mockup, then the code. Apply these rules to a mockup finding:

- When a recorded user decision asks for the difference, the fix updates
  the mockup to match it. A protocol doc changes only under the rules
  above.
- A difference between a mockup and the code that is new in the branch is
  a product bug in the code. The fix changes the code.
- A mockup that differs from a protocol doc is wrong. The fix changes the
  mockup.
- When a mockup and the code already differ on `origin/main`, and no
  protocol doc settles the difference, propose `ask the user`. There the
  mockup can be the stale side.
- When the higher side is wrong, or worse than the lower side, recommend
  its change and propose `ask the user`.
- Sample data in a mockup is not a requirement.
- The wider fix for the class is already in force, this order. Do not
  propose another wider fix for it.

If there are no findings, say so clearly.

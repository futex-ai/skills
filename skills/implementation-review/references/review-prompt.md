# Review prompt

Give this prompt to the reviewer. Replace `<review focus>` with the
`## Review focus` list from the repository's `AGENTS.md`, or delete that
sentence when the repository has none. Replace `<first number>` with the
first free finding number of the branch. Replace `<review folder>` with
the review folder of the branch. The findings file reference of this
skill gives both.

After the last line of the prompt, add a `---` line and paste the outcome
rules in full: the file `references/outcomes.md` of the
`decisions-and-findings` skill. The prompt does not copy them, so that the
reviewer and the working agent read one text.

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
  happens. Harm to the users of the product weighs more than harm to the
  people and agents who build it. Both count. High: wrong output, lost
  data, a security problem, or blocked work. Medium: a visible defect, a
  spec gap with a workaround, or a flaky test or check in the gate. Low:
  wording, style, or a defect that costs little.
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
- Give each option an effort grade. Effort grades one option, not the
  problem. It is your own estimate of the time that the whole job of the
  option takes, for the agent and the user together. The whole job is
  finding the cause, the change, its tests, and the review. Small: under
  an hour. Medium: up to a day. Large: longer. Use the expected change as
  one input: its files, its lines, and its kind. A new dependency, a
  migration, a backend and frontend change, a new mockup, or a new
  protocol section often takes longer. Also weigh the work that the
  change does not show, such as an unknown cause or a new test harness.
  No single input sets the grade. A typical review fix with its test is
  Small. The finding's effort is the grade of the recommended option.
- Recommend one option and say which option best protects the codebase.
  For a finding that the agent may fix without the user, recommend the
  option that the `Action` line names.
- End the finding with an `Action` line that proposes one outcome under
  the outcome rules after this prompt. The working agent makes the final
  call.

The outcome rules follow this prompt, after a `---` line. They hold the
decision test and the fix rule. They say when a finding waits for
the user, which option the `Action` line names, and whether the fix comes
now or after the merge.

For a flaky test that the diff adds or changes, name the nondeterminism
source and the deterministic fix. The deterministic fixes are a fake
clock, event order, captured inputs, operation counts, an explicit
readiness signal, or isolated state. Require the fixer to reproduce the
flake and record pass counts before and after.

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
fallback, or the off branch of a feature flag.

Protocol docs hold the requirements and the decisions in force for an area:
observable behaviour at a boundary, and the reason for each choice. They do
not describe how the code works. Do not treat them as fixed rules. When the
code and a protocol doc disagree, do not assume that the doc is right.
Apply these rules to a docs or spec finding:

- A doc that is silent on how the code works is not a finding. Do not ask
  for a doc to be clarified or enhanced.
- When the code breaks a requirement and the diff did not intend a
  behaviour change, the finding is a product bug in the code.
- The outcome rules say when a doc fix waits for the user, and when a new
  behaviour is a spec gap.
- Do not drop an option, rank it lower, or recommend a different option
  only because it conflicts with a protocol doc. Include the doc update in
  that option and in its effort grade, and recommend the option when it is
  the best one.

If there are no findings, say so clearly.

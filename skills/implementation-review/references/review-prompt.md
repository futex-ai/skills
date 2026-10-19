# Review prompt

Give this prompt to the reviewer. Replace `<review focus>` with the
`## Review focus` list from the repository's `AGENTS.md`, or delete that
sentence when the repository has none.

The scope of the prompt is the diff. When the user explicitly asks for a
review outside the changes, for example of the whole repository or of a
named area, replace the first paragraph of `## Scope` with the scope that
the user named. Do not widen the scope for any other reason.

---

You are reviewing local changes in this repository.

Review the local diff against `origin/main`. You may inspect the repository
read-only for context. Focus on concrete bugs, security issues, missing
tests, docs that contradict the changed code, generated artifact drift,
and implementation risks in the scope below. Pay particular attention to
<review focus> in that scope. Do not treat speculative or purely theoretical
concerns as findings. Do not modify files or automatically fix findings.

## Scope

The scope is the diff: each changed or added hunk, and the code outside the
diff whose behaviour the diff changes. That code includes a caller of a
changed function, a test that covers changed code, a doc that describes
changed behaviour, and a generated artifact of a changed source. A finding
must anchor to the scope.

A problem outside the scope is not a finding. Do not number it, and do not
give it the finding layout. Put it in one list under the heading
`Outside the scope` at the end of the report. Give each problem one line:
the file path and one sentence. The whole list is `Auto-fix: no`. Nobody
fixes these problems in this branch. A flaky test that the diff does not
touch belongs in this list, with its name, failure text, rerun outcome, and
suspected source.

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
effort. Use a hit only as an example. A hit is not a new finding:

```bash
git log --oneline origin/main -- <path>
git log --oneline -i --grep='<keyword>' origin/main
grep -rni '<keyword>' plans/ .context/ 2>/dev/null
```

Return the numbered findings first and the `Outside the scope` list last.
Use the finding layout in the `decisions-and-findings` skill. For every
finding:

- Give it a severity. High: wrong output, lost data, a security problem, or
  blocked work. Medium: a visible defect, or a spec gap with a workaround.
  Low: wording, style, or a rare edge case.
- Give it a category: product bug, security, docs or spec, mockup,
  repository rule, test, performance, code structure, UX wording, or
  process.
- Include the relevant file path and line reference when possible.
- Give the background: enough codebase and feature context, and the terms,
  for a reader with no prior knowledge.
- State the problem: what is wrong, in words that the background explains.
- State the impact of making no change.
- Give solution options labelled A, B, and so on, from the smallest effort
  to the largest. Always consider a wider fix: a rule, test, lint, guard,
  abstraction, or architectural change that prevents the class of issue.
  Give the wider fix its own lettered option. Look for previous examples of
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
  For a finding that you tag `Auto-fix: yes`, recommend the option that the
  tag names.
- End the finding with `Auto-fix: yes, apply <letter>` or `Auto-fix: no,
  because …`.

An option is blocked when:

- It is Large.
- It changes a requirement in a protocol doc without a recorded user
  decision, adds a requirement for new behaviour at the boundary, or
  decides which side of a mockup and product mismatch is right.
- It changes user-visible behaviour beyond the contract.
- It adds a new build error, rejection, gate, lint, or stricter validation.
  This holds for a wider fix too, whatever its effort.
- It deletes, skips, or weakens a test or gate, or raises a time limit.
- It needs an audit exception, credentials, or infrastructure.

`Auto-fix: yes, apply <letter>` is allowed only when at least one option is
not blocked, for a finding about: a product bug (including edge cases,
races, and platform differences); a security issue; docs or spec drift; a
mockup mismatch that a protocol doc already settles; a flaky test that the
diff adds or changes; or a repository-rule violation such as file size,
lint, or layout. The letter names the widest option that is not blocked:
the wider fix when it is not blocked, otherwise the direct fix. A blocked
wider fix does not block the tag. For a flaky test that the diff adds or
changes, name the nondeterminism source and the deterministic fix (fake
clock, event order, captured inputs, operation counts, explicit readiness
signal, or isolated state), and require the fixer to reproduce the flake
and record pass counts before and after.

`Auto-fix: no` for every finding that needs a decision:

- Every option is blocked.
- More than one option has real trade-offs and no option is clearly best.
- The finding is a slow, custom, or low-value test, gate, lint, or check in
  the scope. Ask whether to fix it or remove it, and state what it protects
  and how long it runs.
- The finding is about missing tests, performance, code structure, UX
  wording, or process.

Protocol docs hold the requirements and the decisions in force for an area:
observable behaviour at a boundary, and the reason for each choice. They do
not describe how the code works. Do not treat them as fixed rules. When the
code and a protocol doc disagree, do not assume that the doc is right.
Apply these rules to a docs or spec finding:

- Docs or spec drift is a doc that contradicts the changed code. A doc that
  is silent on how the code works is not a finding. Do not ask for a doc to
  be clarified or enhanced.
- The wider fix for the class is already in force, the `documentation`
  skill. Do not propose another wider fix for it.
- When the code breaks a requirement and the diff did not intend a
  behaviour change, the finding is a product bug in the code.
- When the diff changes behaviour that a requirement states, and the plan
  records the user's decision for that change, the fix updates the doc:
  `Auto-fix: yes`, with the doc update as the named option. Without a
  recorded decision, tag it `Auto-fix: no`, because the user decides which
  side is right.
- A behaviour at the boundary that the diff adds and no requirement covers
  is a spec gap. Report it as one finding with `Auto-fix: no`, because the
  user reviews each new requirement.
- When a protocol doc in the scope names source files, functions, or
  internal mechanics, or records history, the fix moves that content to
  its home: the crate README for entry points, the plan for history, the
  code for mechanics. `Auto-fix: yes`, with the move as the named option.
- Do not drop an option, rank it lower, or recommend a different option
  only because it conflicts with a protocol doc. Include the doc update in
  that option and in its effort grade, and recommend the option when it is
  the best one.

If there are no findings, say so clearly and mention residual test risk.

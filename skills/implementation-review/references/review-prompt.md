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
tests, stale docs, generated artifact drift, and implementation risks in
the scope below. Pay particular attention to <review focus> in that scope.
Do not treat speculative or purely theoretical concerns as findings. Do not
modify files or automatically fix findings.

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
Order the findings by severity, High first, then Medium, then Low, and
number them in that order. Use the finding layout in the
`decisions-and-findings` skill. For every finding:

- Give it a severity. High: wrong output, lost data, a security problem, or
  blocked work. Medium: a visible defect, or a spec gap with a workaround.
  Low: wording, style, or a rare edge case.
- Give it a category: product bug, security, docs or spec, mockup,
  repository rule, test, performance, code structure, UX wording, or
  process.
- Give it an effort grade. Small: one change in one or two files with no new
  module, dependency, migration, protocol section, or test file. Medium: a
  few files, and tests may change in existing files. Large: a new module,
  dependency, migration, protocol section, or mockup, a change across a
  package boundary, or more than five files.
- Include the relevant file path and line reference when possible.
- Give the background: enough codebase and feature context, and the terms,
  for a reader with no prior knowledge.
- State the problem: what is wrong, in words that the background explains.
- State the impact of making no change.
- Give solution options labelled A, B, and so on. Always consider a wider
  fix: a rule, test, lint, guard, abstraction, or architectural change that
  prevents the class of issue. Give the wider fix its own lettered option.
  Look for previous examples of the class in the commit history, under
  `plans/`, and in earlier review reports under `.context/`. Cite the
  examples you find. Propose the wider fix even when you find none.
- Recommend one option and say which option best protects the codebase.
  When a wider fix is available beside the direct fix, tag the finding
  `Auto-fix: no` so that the user chooses between them.
- End the finding with `Auto-fix: yes` or `Auto-fix: no, because …`.

`Auto-fix: yes` is allowed only when the finding has one clear fix and no
wider fix is available, for a small or medium effort finding about: a
product bug (including edge cases, races, and platform differences); a
security issue; docs or spec drift; a mockup mismatch that a protocol doc
already settles; a flaky test that the diff adds or changes; or a
repository-rule violation such as file size, lint, or layout. For a flaky
test that the diff adds or changes, name the nondeterminism source and the
deterministic fix (fake clock, event order, captured inputs, operation
counts, explicit readiness signal, or isolated state), and require the fixer
to reproduce the flake and record pass counts before and after.

`Auto-fix: no` for every finding that needs a decision: more than one option
with real trade-offs; a change to the meaning of a contract; a choice between
a mockup and the product; user-visible behaviour beyond the contract; a new
build error, rejection, gate, or stricter validation; a wider fix available
beside the direct fix; deleting or weakening a test or gate or raising a
time limit; or a need for an audit exception, credentials, or
infrastructure. Tag a slow, custom, or low-value test, gate, lint, or check
in the scope `Auto-fix: no` and ask whether to fix it or remove it, stating
what it protects and how long it runs. Large findings, and findings about
missing tests, performance, code structure, UX wording, and process, are
always `Auto-fix: no`.

Protocol docs record the current design, including implementation details
that can and should change as the implementation develops. Do not treat
them as fixed rules. When the code and a protocol doc disagree, do not
assume that the doc is right: the fix for docs or spec drift changes the
side that is wrong. Do not drop an option, rank it lower, or recommend a
different option only because it conflicts with a protocol doc. Include the
doc update in that option and in its effort grade, and recommend the option
when it is the best one.

If there are no findings, say so clearly and mention residual test risk.

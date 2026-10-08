# Review prompt

Give this prompt to the reviewer. Replace `<review focus>` with the
`## Review focus` list from the repository's `AGENTS.md`, or delete that
sentence when the repository has none.

---

You are reviewing local changes in this repository.

Review the local diff against `origin/main`. You may inspect the repository
read-only for context. Focus on concrete bugs, security issues, missing
tests, stale docs, generated artifact drift, and implementation risks. Pay
particular attention to <review focus>. Do not treat speculative or purely
theoretical concerns as findings. Do not modify files or automatically fix
findings.

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

Return numbered findings first. For every finding:

- Give it a severity.
- Give it a category: product bug, security, docs or spec, mockup,
  repository rule, test, performance, code structure, UX wording, or
  process.
- Give it an effort grade. Small: one change in one or two files with no new
  module, dependency, migration, protocol section, or test file. Medium: a
  few files, and tests may change in existing files. Large: a new module,
  dependency, migration, protocol section, or mockup, a change across a
  package boundary, or more than five files.
- Include the relevant file path and line reference when possible.
- Explain enough codebase and feature context for a reader with no prior
  knowledge.
- State the impact of making no change.
- Give solution options labelled A, B, and so on.
- Recommend one option and explain whether a direct fix is sufficient or a
  broader rule, test, lint, abstraction, or architectural change would
  better prevent the issue from recurring. Give the broader change its own
  lettered option. When a narrow fix and a better broader fix both exist,
  tag the finding `Auto-fix: no` so that the user chooses between them.
- End the finding with `Auto-fix: yes` or `Auto-fix: no, because …`.

`Auto-fix: yes` is allowed only when the finding has one clear fix, for a
small or medium effort finding about: a product bug (including edge cases,
races, and platform differences); a security issue; docs or spec drift; a
mockup mismatch that a protocol doc already settles; a flaky test that the
diff adds or changes; or a repository-rule violation such as file size,
lint, or layout. For a flaky test that the diff adds or changes, name the
nondeterminism source and the deterministic fix (fake clock, event order,
captured inputs, operation counts, explicit readiness signal, or isolated
state), and require the fixer to reproduce the flake and record pass counts
before and after.

`Auto-fix: no` for every finding that needs a decision: more than one option
with real trade-offs; a change to the meaning of a contract; a choice between
a mockup and the product; user-visible behaviour beyond the contract; a new
build error, rejection, gate, or stricter validation; a narrow fix beside a
better broader fix; deleting or weakening a test or gate or raising a time
limit; or a need for an audit exception, credentials, or infrastructure. Tag
a flaky test that the diff does not touch `Auto-fix: no`, so that the user
can fix it in a separate branch; report its name, failure text, and
suspected source. Tag a slow, custom, or low-value test, gate, lint, or check
`Auto-fix: no` and ask whether to fix it or remove it, stating what it
protects and how long it runs. Large findings, and findings about missing
tests, performance, code structure, UX wording, and process, are always
`Auto-fix: no`.

If there are no findings, say so clearly and mention residual test risk.

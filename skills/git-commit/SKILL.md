---
name: git-commit
description: Use before you commit and directly after, when you write a commit message or a pull request title and description, when you squash, when the diff against origin/main deletes or renames a file, feature, test, fixture, or command, when you find dead code, an unused item, or a path that the product never runs, when you are not sure whether a plan or doc passage is live content or history, and when a link check fails on a link in history content.
---

# Git commit

Do not delete or override functionality already on `origin/main` without
explicit user approval. Functionality includes live code, its tests, APIs,
docs, mockups, plans, migrations, and schema. Dead code needs no approval.
The section "Dead code" below says when code is dead. Merges and rebases
have their own procedure in the `git-merge` skill.

## Before and after each commit

Run `scripts/audit-deletions.sh`, which prints:

```sh
git diff --name-status origin/main
git diff --diff-filter=D --name-status origin/main
git diff --name-status origin/main..HEAD   # after the commit
```

Stop unless each deletion is dead code under the section below or has the
user's explicit approval. A feature-wide reduction is functionality. Record
every removal and its related cleanup in the commit or PR description. For
dead code, record the search that proved it dead. For functionality,
record the approval.

Run `git add -A` before you commit so that newly created files are tracked
and included in the commit, the push, and the review diff. Do not commit
scratch output; it lives under the git-ignored `.context/`.

## Dead code

Dead code is code that the product never runs. Deleting it needs no
approval. Code is dead only when all of these hold:

1. No product code, test of live code, script, configuration, build
   file, or generated artifact references it. Search the repository for
   its name. An
   unused-item warning from the compiler or the linter proves this for a
   private item. The warning counts only when the build compiles every
   feature, platform, and test target.
2. No indirect path reaches it: no route table, registry, plugin loader,
   file-name convention, string key, dynamic import, or reflection names
   it. Search for each string that could name it.
3. No consumer outside the code reaches it. An entry point is
   functionality: a command, a script, a migration, or an export of a
   published package. The package manifest says whether a package is
   published.
4. Nothing keeps it on purpose: no annotation such as
   `#[expect(dead_code)]`, no feature flag, no open plan TODO, and no
   protocol doc that requires it.

Everything else is functionality, also when the product runs it rarely:

- An error path, a fallback, the off branch of a feature flag, or a
  platform branch.
- An entry point.
- A helper, a fixture, or a mock that a test of live code uses. Test code
  is not product code, but a test of live code is functionality.

Deleting or overriding functionality needs explicit user approval. When a
condition is in doubt, the code is functionality. Ask.

Example: a change deleted a backend, and a shell path that only that
backend set stayed behind. No live code sets the path, so the path is
dead. Delete the path and the tests that cover only it. Move the older
tests that reach live behaviour through the path to the live path, with
the same assertions.

When you delete dead code:

- Delete the dead code that your change touches or leaves unused. Report
  other dead code that you find, for a separate branch.
- The tests that cover only the dead code are dead code. Delete them.
- A test that reaches live behaviour only through the dead code moves to
  the live path. Keep every assertion.
- Apply the conditions to each item that the deletion leaves unused.
  Delete each item that meets them: imports, helpers, types, styles,
  fixtures, and files.
- Save the search commands and their output under `.context/`. Record
  each deletion and the search that showed it dead in the commit or PR
  description.
- Update the stale references, as the next section says.

## Removals and renames

When a change removes or renames a feature, test, fixture, scenario,
command, or file, search `docs/`, `plans/`, and every `README.md` for its
name. Update each stale reference in live content in the same change.
Record each plan edit in the commit or PR description.

## Live and history

- `docs/` and every `README.md` are live content.
- In an active plan, completed milestones and checked TODOs are history; all
  other content is live.
- In a completed plan, open review findings and unchecked post-merge
  follow-ups are live; all other content is history.
- Do not change the words of history, also when a later change makes them
  stale. The next section says when to correct a false fact in history.
- When the repository's link check fails on a link inside history content,
  replace the link with a GitHub permalink at a commit where the target
  still matches the text. Start with the commit that wrote the link. For a
  squash-merged PR, look for that commit in `refs/pull/<number>/head`. For
  a line in a Markdown file, put `?plain=1` before `#L<number>`.

## False facts in history

A false fact in history is an error. Correct it without approval when
all of these hold:

1. The branch wrote it.
2. It is a count, a name, a path, a link, a commit, or a date.
3. It was false when the branch wrote it. A fact that a later change
   made stale was true, so it keeps its words.
4. The record gives the true value, for example the evidence file, the
   commit, or the command output.

Change only the false words. Name the old and the new value in the commit
message. When the true value means that a checked TODO is not done, ask
the user.

Example: a checked smoke-test TODO said "25 checks passed", but the log of
that run showed 22 checks. The count was false when the branch wrote it.
The fix corrects the count and names both values in the commit message.

## Message format

Every commit message and pull request title uses the Conventional Commits
format: `<type>(<optional scope>): <description>`, a blank line, then the
body. The format enables automated changelogs and readable history.

- Commit titles use at most 50 characters. Pull request titles and their
  squash commit titles use at most 72 Unicode code points.
- The body has no strict length limit. Always include a body that explains
  what changed and why, not only a title.
- A commit may hold multiple entries when it has distinct change types.
  Separate entries with a blank line. Order them by type priority: `feat`,
  `fix`, `perf`, `refactor`, `build`, `ci`, `test`, `docs`, `style`,
  `chore`.
- Record in the commit or PR description:
  - every removal and its related cleanup, with the search that proved
    the code dead or the approval for the functionality
  - each plan edit made for a rename or removal
  - each corrected false fact in history, with the old and the new value
  - each intentional merge decision with the paths it affects
  - the review finding that a fix commit resolves, by number
- When a later commit changes what the pull request description says,
  update the description.

## Examples

Compact titles (add a body in real commits):

```
feat: add cargo xtask lint command
fix(linear-webhook): include check run URLs in failure handling
build(ios): skip device arch in dev builds
chore: update app version to 2.0.11
refactor(linear-webhook): extract reusable webhook actions
feat(wallet): add rewards transfer to merge_wallet_admin endpoint
fix(bungee): enforce $1.00 minimum USD output amount threshold
docs(claude): prefer `dyn T` over generics
perf(bungee-client-http): optimize request batching
```

One commit with two entries, `refactor` before `chore`:

```
refactor: adopt Rust 1.90 idioms, fix new lints

- Replace nested conditionals with if-let chains across crates
- Remove unused structs, imports, and dead test helpers
- Add #[expect(dead_code)] with reasons where code is gated by features
- Tighten lifetimes and return types
- Minor logic cleanups and early returns; no functional changes intended

chore(rust): bump workspace to Rust 1.90

- Update codebase to compile cleanly under Rust 1.90 and new lints
```

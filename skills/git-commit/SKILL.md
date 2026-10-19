---
name: git-commit
description: Use before and directly after you commit, when you write a commit message or a pull request description, when you squash, when the diff deletes or renames a file, feature, test, or command, when you are not sure whether a passage is live content or history, and when a link check fails on history content. Covers the deletion audit, stale references, live and history content, GitHub permalinks, and the Conventional Commits format.
---

# Git commit

Do not delete or override anything already on `origin/main`, including
code, APIs, tests, docs, mockups, plans, migrations, and schema, without
explicit user approval. Merges and rebases have their own procedure in the
`git-merge` skill.

## Before and after each commit

Run `scripts/audit-deletions.sh`, which prints:

```sh
git diff --name-status origin/main
git diff --diff-filter=D --name-status origin/main
git diff --name-status origin/main..HEAD   # after the commit
```

Stop unless each deletion or feature-wide reduction is authorized. Record
every approved removal and its related cleanup in the commit or PR
description.

Run `git add -A` before you commit so that newly created files are tracked
and included in the commit, the push, and the review diff. Do not commit
scratch output; it lives under the git-ignored `.context/`.

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
- Do not change the words of history.
- When the repository's link check fails on a link inside history content,
  replace the link with a GitHub permalink at a commit where the target
  still matches the text. Start with the commit that wrote the link. For a
  squash-merged PR, look for that commit in `refs/pull/<number>/head`. For
  a line in a Markdown file, put `?plain=1` before `#L<number>`.

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
- Record in the commit or PR description: every approved removal and its
  related cleanup, each plan edit made for a rename or removal, each
  intentional merge decision with the paths it affects, and the review
  finding that a fix commit resolves, by number.

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

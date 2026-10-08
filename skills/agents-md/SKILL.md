---
name: agents-md
description: Create a repository's thin AGENTS.md, or migrate a monolithic AGENTS.md and docs/dev rule files into it. Use when a repository has no AGENTS.md, when it still carries the full General, Readme, Docs, Plans, Rust, Databases, Git, and Bash timeout sections, or when the user asks to migrate, slim down, or align a repository's agent rules with the shared skills.
---

# AGENTS.md

The target is an `AGENTS.md` of about 50 lines that holds only what is
specific to the repository and lists the shared skills that apply.
Everything general lives in the shared skills and in the always-on global
rules. [templates/AGENTS.md](templates/AGENTS.md) is the template.

## New repository

1. Copy the template to the repository root as `AGENTS.md`.
2. Fill every section. Delete the `rust`, `databases`, `mockups`, and
   `product-ui` lines when the repository has none of that.
3. Create `CLAUDE.md` as a symlink to `AGENTS.md`.

## Section map for a monolith

| Monolith section | Now lives in |
| --- | --- |
| General: response style and reporting | the template's `## Communication` section, and the global always-on rules |
| General: retries, file length, scratch output, testing habits, safety | the global always-on rules |
| General: targeted tests, gate, commit, push, review loop | `finish-work` |
| General: review format and auto-fix | `implementation-review` |
| General: flaky tests, no wall-clock assertions | `deterministic-tests` |
| General: product data, copy, left-border rule | `product-ui` |
| Readme, Docs, Protocol Docs | `documentation` |
| Mockups | `mockups` |
| Plans | `plans` |
| Rust and its subsections | `rust` |
| Databases | `databases` |
| Git: format, limits, examples, deletion audit, stale references, live and history | `git-commit` |
| Git: mainline preservation during merge and rebase | `git-merge` |
| Bash Tool Timeout Configuration | nowhere; obsolete, drop it |

## Migration procedure

1. Read the repository's `AGENTS.md`, `docs/dev/*.md` if present, and
   `docs/implementation-review-prompt.md` if present. The shared skill text
   is the canonical version of every general rule.
2. Walk every rule and classify it:
   - **Covered**: the shared skill or the global file says the same thing.
     Drop it.
   - **Repository-specific**: commands, paths, suite names, size caps and
     the lint that enforces them, link checks, generated directories,
     product locations and the shared UI library, review focus areas,
     production status. Keep it in the matching template section.
   - **Conflicting**: the repository says something different from the
     shared skill, for example an older plan index rule or an older review
     rule. The user decides.
   - **Uncovered general rule**: a rule that belongs in a shared skill but
     is not there yet. The user decides. Never drop it silently.
3. Send the checkpoint message described below and wait for the answers.
   The new `AGENTS.md` replaces content on `origin/main`, so change no file
   before this checkpoint.
4. Write the new `AGENTS.md` from the template with the decisions applied.
   Fill every section. Keep `CLAUDE.md` as a symlink to `AGENTS.md`.
5. Delete the approved files: the `docs/dev/*.md` files now covered by
   skills, and `docs/implementation-review-prompt.md` if the shared review
   prompt replaces it. Then search `docs/`, `plans/`, and every `README.md`
   for links to them. Update references in live content to name the skill
   instead. Do not change the words of history; replace a failing history
   link with a GitHub permalink. See the `git-commit` skill.
6. Run the repository's Markdown and link checks. Commit with the
   `git-commit` skill, for example
   `docs(agents): point AGENTS.md at shared skills`, and push.
7. Send the final report described below.

## Communicating with the user

The global always-on rules say how to ask for decisions and how to report.
This task has one checkpoint message and one final report.

**The checkpoint message**, after classification and before any change:

- One line with the counts: rules covered, kept, conflicting, uncovered.
- The repository-specific rules you will keep, grouped by template section,
  one line each. Do not quote the old file at length.
- The numbered decisions. Every conflict, every uncovered rule, and every
  file deletion is one decision. Give the repository's wording and the
  shared skill's wording when there is one.
  - A conflict offers: A, use the shared rule; B, keep the repository's rule
    as an override under `## Repository rules`; C, change the shared skill
    and apply it everywhere.
  - An uncovered rule offers: A, add it to a named shared skill with the
    proposed text; B, keep it as a repository rule; C, drop it.
  - A deletion offers: A, delete and update links; B, keep the file.
- A short list of what happens after the answers: write the file, delete
  the approved files, update links, run checks, commit, push.

**The final report**, after the commit, adds to the standard report:

- The line count of `AGENTS.md` before and after.
- The files deleted and the links updated.
- The proposed shared-skill changes, with their text, so that the user can
  apply them in the skills repository.

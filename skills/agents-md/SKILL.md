---
name: agents-md
description: Use when a repository has no AGENTS.md or CLAUDE.md, when its AGENTS.md or docs/dev rule files still carry General, Readme, Docs, Plans, Rust, Databases, Git, or Bash timeout sections, when a repository rule duplicates or conflicts with a shared skill, and when the user asks to create, migrate, slim down, or align a repository's agent rules with the shared skills.
---

# AGENTS.md

The target is an `AGENTS.md` of about 50 lines that holds only what is
specific to the repository. Everything general lives in the shared skills
and in the always-on global rules. The file does not list the shared
skills. An agent sees every skill's description, and the description says
when to read it. [templates/AGENTS.md](templates/AGENTS.md) is the template.

## New repository

1. Copy the template to the repository root as `AGENTS.md`.
2. Fill every section. Delete each line and section that the template
   marks for deletion when the repository has none of that.
3. Create `CLAUDE.md` as a symlink to `AGENTS.md`.

## Section map for a monolith

| Monolith section | Now lives in |
| --- | --- |
| General: response style and reporting | the template's `## Communication` section, the global always-on rules, and `decisions-and-findings` |
| General: retries, file length, scratch output, safety | the global always-on rules |
| General: where application-, crate-, and feature-specific rules live | `documentation` |
| General: what to test, test levels, failing tests, removing tests | `testing` |
| General: targeted tests, smoke tests, gate, commit, push, review loop | `finish-work` |
| General: review format and auto-fix | `implementation-review`, with the layout in `decisions-and-findings` |
| General: flaky tests, no wall-clock assertions | `testing` |
| General: product data, copy, left-border rule | `product-ui` |
| Readme, Docs, Protocol Docs | `documentation` |
| Mockups | `mockups` |
| Plans | `plans` |
| Rust and its subsections | `rust` |
| Databases | `databases` |
| Git: format, body length, examples, deletion audit, dead code, stale references, live and history | `git-commit` |
| Git: commit title length limit | nowhere; removed from `git-commit`, drop it |
| Git: mainline preservation during merge and rebase | `git-merge` |
| Bash Tool Timeout Configuration | nowhere; obsolete, drop it |

## Migration procedure

1. Update the shared skills before you compare rules with them. Get the
   latest commit of `futex-ai/skills` `main` with
   `git ls-remote https://github.com/futex-ai/skills.git refs/heads/main`.
   Bring the installed skills to that commit:
   - Skills linked from a clone of `futex-ai/skills`: run
     `./scripts/update.sh` in the clone. It fast-forwards a clean `main`
     and relinks the skills. Its `HEAD` must then be that commit.
   - Skills installed with `npx skills add`: run `npx skills update -g -y`.
   - Any other case, or a failed update: clone `main` under `.context/` and
     read the skills from that clone.
2. If step 1 brought a newer version of this skill, read that version.
   Read the repository's `AGENTS.md`, `docs/dev/*.md` if present, and
   `docs/implementation-review-prompt.md` if present. The shared skill text
   is the canonical version of every general rule.
3. Walk every rule and classify it:
   - **Covered**: the shared skill or the global file says the same thing.
     Drop it.
   - **Repository-specific**: commands, paths, suite names, size caps and
     the lint that enforces them, link checks, generated directories,
     product locations and the shared UI library, review focus areas,
     production status. Keep it in the matching template section.
   - **Package-specific**: a rule for `## Repository rules` that applies
     only to work on one application, package, or feature. Move it to the
     `README.md` next to its code, as the `documentation` skill says.
   - **Conflicting**: the repository says something different from the
     shared skill, for example an older plan index rule or an older review
     rule. The user decides.
   - **Uncovered general rule**: a rule that belongs in a shared skill but
     is not there yet. The user decides. Never drop it silently.
4. Send the checkpoint message described below and wait for the answers.
   The new `AGENTS.md` replaces content on `origin/main`, so change no
   tracked file in this repository before this checkpoint.
5. Write the new `AGENTS.md` from the template with the decisions applied.
   Fill every section. Move each package-specific rule to its `README.md`.
   Keep `CLAUDE.md` as a symlink to `AGENTS.md`.
6. Delete the approved files: the `docs/dev/*.md` files now covered by
   skills, and `docs/implementation-review-prompt.md` if the shared review
   prompt replaces it. Then search `docs/`, `plans/`, and every `README.md`
   for links to them. Update references in live content to name the skill
   instead. Do not change the words of history; replace a failing history
   link with a GitHub permalink. See the `git-commit` skill.
7. Run the repository's Markdown and link checks. Commit with the
   `git-commit` skill, for example
   `docs(agents): point AGENTS.md at shared skills`, and push.
8. Send the final report described below.

## Communicating with the user

The global always-on rules and the `decisions-and-findings` skill say how to
ask for decisions and how to report.
This task has one checkpoint message and one final report.

**The checkpoint message**, after classification and before any change:

- One line with the counts: rules covered, kept, moved, conflicting,
  uncovered.
- One line with the `futex-ai/skills` commit from step 1.
- The repository-specific rules you will keep, grouped by template section,
  and the package-specific rules you will move, grouped by `README.md`.
  One line each. Do not quote the old file at length.
- The numbered decisions. Every conflict, every uncovered rule, and every
  file deletion is one decision. Give the repository's wording and the
  shared skill's wording when there is one.
  - A conflict offers: A, use the shared rule; B, keep the repository's rule
    as an override under `## Repository rules`; C, change the shared skill
    and apply it everywhere.
  - An uncovered rule offers: A, add it to a named shared skill with the
    proposed text; B, keep it as a repository rule; C, drop it.
  - A deletion offers: A, delete and update links; B, keep the file.
- A short list of what happens after the answers: write the file, move
  the package-specific rules, delete the approved files, update links, run
  checks, commit, push.

**The final report**, after the commit, adds to the standard report:

- The line count of `AGENTS.md` before and after.
- The package-specific rules moved, the files deleted, and the links
  updated.
- The proposed shared-skill changes, with their text, so that the user can
  apply them in the skills repository.

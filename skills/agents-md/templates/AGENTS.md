# A guide for agents

<One short paragraph: what this repository is, the stack, and where the code
lives. Example: "Mokly is a TypeScript CLI and viewer for design mockups.
Source is under `src/`, the viewer package under `packages/viewer`, and the
Rust task runner under `xtask/`.">

This file holds the rules that are specific to this repository. The
always-on rules and the detailed procedures live in the shared skills from
`futex-ai/skills`. Read the skill at the named moment instead of guessing
the rule.

## Shared skills

- `finish-work`: before you say work is complete, and before you commit.
- `plans`: before you create, edit, or tick a plan under `plans/`.
- `implementation-review`: after you push, before you run or apply a
  review.
- `deterministic-tests`: when a test flakes, or when a test would assert
  elapsed time.
- `git-commit`: before and after you commit, and when you open a pull
  request.
- `git-merge`: before you merge or rebase, and after each merge commit.
- `documentation`: before you edit a `README.md`, a doc, or a protocol doc.
- `rust`: before you edit Rust. <delete if the repository has no Rust>
- `databases`: before you touch migrations, Diesel, or store crates.
  <delete if none>
- `mockups`: before you create or change a mockup under `docs/mockups`.
  <delete if none>
- `product-ui`: before you implement or change a user-facing screen or
  copy. <delete if none>

## Communication

- Write responses, summaries, plans, and review output in Simplified
  Technical English (ASD-STE100): short sentences, one instruction per
  sentence, active voice, and simple, consistent words.
- Assume the reader has no context. Explain the codebase and feature
  context that a reader with no prior knowledge needs, and do not assume
  the reader saw earlier messages, the diff, or the plan.
- Report outcomes faithfully. Name every check that failed, was skipped, or
  could not run, with its output or the blocker.
- Ask for all decisions in one numbered message. For each decision give
  its severity and effort, the context, the impact if no action is taken,
  lettered options, and a recommended option. Do the independent work
  first, then stop and wait.
- End every task with a final report: what changed and the commit, each
  decision and its outcome, the checks that ran, anything skipped, and the
  outstanding decisions or review items that still need the user.

## Commands

- Build: `<command>`
- Targeted tests: `<command for one file or name pattern>`
- Early check (format, lint, file length): `<command>`
- Complete gate: `<command>`. <How failures report, for example "A local
  run stops at the first failed suite.">
- Format: `<command>`
- Mockup check: `<command>` <delete if none>

## Repository rules

<Rules that only this repository needs. Examples:>

- Changed TypeScript files are capped at 300 lines and protocol Markdown at
  250 lines by the repository gate.
- `tests/markdown_links.test.ts` checks local links in `AGENTS.md`,
  `docs/`, `plans/`, and every `README.md`.
- Never commit anything under `<generated directory>`.

## Product

<Where user-facing code lives and which shared UI library to check first.
Delete this section if the repository has no product UI.>

- Screens live in `<path>`. Check `<shared UI library>` first, then
  `<app components path>`, before you create a component.

## Review focus

<Areas the implementation review must pay particular attention to, beyond
the generic focus list in the `implementation-review` skill.>

- <Example: app independence, generated-output safety, server and watcher
  lifecycle, protocol alignment.>

## Status

- <Example: "This project is not in production. Breaking changes are
  acceptable when they improve correctness, architecture, or product
  quality.">

# A guide for agents

<One short paragraph: what this repository is, the stack, and where the code
lives. Example: "Mokly is a TypeScript CLI and viewer for design mockups.
Source is under `src/`, the viewer package under `packages/viewer`, and the
Rust task runner under `xtask/`.">

This file holds the rules that are specific to this repository. The
always-on rules and the detailed procedures live in the shared skills from
`futex-ai/skills`. Each skill's description says when to read it. Read the
skill at that moment instead of guessing the rule.

## Shared skills

<Only what a skill description cannot know about this repository. Delete
the section when there is nothing to say. Examples:>

- Plans live under `<path>`, not `plans/`.
- The `rust`, `databases`, and `shared-types` skills do not apply. This
  repository has no Rust.

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
  its severity and effort, the background, the problem, the impact if no
  action is taken, lettered options, and a recommended option. Do the
  independent work
  first, then stop and wait.
- End every task with a final report: what changed and the commit, each
  decision and its outcome, the checks that ran, anything skipped, and the
  outstanding decisions or review items that still need the user.

## Commands

- Build: `<command>`
- Targeted tests: `<command for one file or name pattern>`
- Typecheck: `<command>` <delete if the repository has no TypeScript>
- Early check (format, lint, file length): `<command>`
- Complete gate: `<command>`. <How failures report, for example "A local
  run stops at the first failed suite.">
- Format: `<command>`
- Generate types: `<command>` <delete if none>
- Mockup check: `<command>` <delete if none>

## Repository rules

<Rules that only this repository needs. Examples:>

- Changed TypeScript files are capped at 300 lines and protocol Markdown at
  250 lines by the repository gate.
- `tests/markdown_links.test.ts` checks local links in `AGENTS.md`,
  `docs/`, `plans/`, and every `README.md`.
- Never commit anything under `<generated directory>`.
- TypeScript types under `<generated types directory>` are generated from
  `<crate>` by `<command>`. Never hand-edit them.
- Boundary types send 64-bit integers, decimals, and dates as `<form>`.

## Product

<Where user-facing code lives and which shared UI library to check first.
Delete this section if the repository has no product UI.>

- Screens live in `<path>`. Check `<shared UI library>` first, then
  `<app components path>`, before you create a component.

## Review focus

<Areas the implementation review must pay particular attention to in the
changed code, beyond the generic focus list in the `implementation-review`
skill.>

- <Example: app independence, generated-output safety, server and watcher
  lifecycle, protocol alignment.>

## Status

- <Example: "This project is not in production. Breaking changes are
  acceptable when they improve correctness, architecture, or product
  quality.">

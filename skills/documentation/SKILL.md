---
name: documentation
description: Use before you edit a README.md, a crate README, anything under docs/, an architecture doc, or a protocol doc, before you add a rule to AGENTS.md or CLAUDE.md, when a behaviour change could leave a doc stale, when the code and a protocol doc disagree, when you decide whether a sentence belongs in a protocol doc, a README, a plan, a test, or the code, and when a change or a review option conflicts with a protocol doc.
---

# Documentation

Docs under `docs/`, protocol docs, mockups, and every `README.md` are part
of the spec. Keep them aligned with the behaviour of the implementation in
the same change. A doc is stale when it contradicts the code. A doc that is
silent on a detail is not stale. A doc is not stale for behaviour that its
status line names. When a change removes or renames anything, search
`docs/`, `plans/`, and every `README.md` for its name. The `git-commit`
skill says how. Mockups have their own rules in the `mockups` skill.

## The home of each kind of content

Each fact lives in one place. Other docs link to it.

| Content | Home |
| --- | --- |
| A requirement: observable behaviour at a boundary | The protocol doc |
| A decision in force, with the rejected alternative and the reason | The protocol doc, next to its requirement |
| Components, their responsibilities, and their boundaries | The architecture doc |
| Entry points into the code: files, types, functions | The crate or area `README.md`, under `### Key Code` |
| A rule for work on one application, package, or feature | The `README.md` next to its code |
| A rule for work across the repository | The repository `AGENTS.md`, under `## Repository rules` |
| How the code works: mechanics, call order, module layout | The code and its doc comments |
| The design of one change, its dated decisions, and history | The plan under `plans/` while the change is open, then the pull request description |
| Work that waits until after the merge | A follow-up item under `plans/follow-ups/` |
| Which behaviour of a doc is not built yet, and the work that will build it | The status line of that doc, below its title |
| Cases and examples | The tests |
| An API surface, a schema, a type list | Generated reference |

## Workspace README

- A summary of the key features of the project, not a long list of every
  feature.
- User-facing interface documentation: CLI, API, and similar.
- Developer get-started steps.
- Key code jumping-in points.
- Links to the architecture doc, the protocol docs, and the `plans/`
  directory.

Read the `README.md` for the area you work on before you change it, and
update it with any new useful context in the same change.

## Rust crate READMEs

- Treat every crate `README.md` as user-facing documentation good enough to
  publish on crates.io.
- Start with a short statement of what the crate is for, where it fits in
  the workspace, and when a caller should depend on it.
- Document the public behaviour and integration boundary, not only internal
  implementation details.
- Include these sections, in this order: `## Responsibilities`,
  `## What This Crate Does`, `## Quick Start`, `## Development`,
  `### Key Code`, `### Related Docs`.
- `## Quick Start` includes example code or runnable commands, not only
  prose.
- `### Key Code` names the entry points: the files, types, and functions
  that a reader opens first, each with one sentence on what it does. This
  is the home of code references, so that protocol docs do not need them.
  Update it when an entry point moves or changes.
- `### Related Docs` links to the protocol docs and the architecture doc
  that the crate implements.
- For binary crates or user-facing tools, document the CLI or external
  interface, not only the internal architecture.
- Keep examples aligned with the real public API and current behaviour. Do
  not describe internals that callers cannot use directly.
- Keep crate READMEs concise and high-signal: main use cases and
  boundaries, not every file or minor feature.
- When a crate has important neighbouring crates, name them and explain the
  boundary so that ownership is clear.

## Docs (`docs/`)

- Docs stay aligned with the behaviour of the implementation. Fix a doc
  that contradicts the code in the same change.
- Docs are consistent with themselves: no conflicting statements.
- Docs may be nested in multiple directories.
- A gap in the requirements found during implementation is a decision
  when it passes the decision test in the `decisions-and-findings` skill.
  See "Protocol docs change with the behaviour" below.

## Architecture docs

An architecture doc describes the structure that no single piece of code
shows: the components of the system, the responsibility of each, the
boundaries between them, and the flow of data across the boundaries. It
lives under `docs/`, for example `docs/architecture.md` or
`docs/architecture/<area>.md`.

- Describe components and their responsibilities, not modules, files, or
  functions. Code-level structure goes stale on every refactor. A component
  boundary does not.
- Keep few architecture docs: one for the system, and one for a large area
  when the system doc passes the length target.
- Update an architecture doc when a component, a responsibility, or a
  boundary changes. A change inside a component needs no update.
- Apply the same length target as protocol docs.

## Generated reference

Reference content lists what exists: an API surface, a schema, a type list,
a command list. Hand-written reference drifts on every addition.

- When a generator exists, generate the reference from the code and commit
  the output. The `shared-types` skill gives the generators for types that
  cross between Rust and TypeScript, and utoipa gives the OpenAPI document
  for an HTTP API.
- Keep in prose only the semantics that a generator cannot express, such as
  idempotency, authorization, and ordering rules. These are requirements and
  belong in the protocol doc.
- Do not hand-edit generated output. Regenerate it in the same change as
  the code.

## Protocol docs (`docs/protocol`), the specs

A protocol doc holds the requirements and the decisions in force for one
area. A human reviews it before implementation starts. The post-push review
checks the behaviour of the code against it. Every change to a protocol doc
is therefore a change to a requirement or to a decision, and is worth a
review.

- A requirement states observable behaviour at a boundary: an interface, a
  wire format, a state transition, an error, a limit, or what a user sees.
  Write one requirement in each sentence.
- Apply this test to every sentence: could a different implementation
  satisfy the sentence? If yes, the sentence is a requirement and stays. If
  no, the sentence describes the implementation. Move it to the home that
  the table above gives.
- A decision in force stands next to the requirement that it explains. Give
  the choice, the rejected alternative, and the reason, in one or two
  sentences. Its purpose is to stop an agent from proposing the rejected
  alternative again.
- Do not keep a dated decision log in a protocol doc. The plan holds the
  dated record of each decision. When the change deletes its plan, the
  pull request description keeps that record. When a later decision
  supersedes an earlier one, that record holds the history, and the
  protocol doc shows only the decision in force.
- Do not name source files, functions, hooks, modules, or internal call
  order. Do not record history, such as what the code did before a change.
  Do not give implementation tips. Do not list every case: state the rule
  once and let the tests hold the cases.
- A protocol doc is complete when a reader can tell, for every behaviour at
  the boundary, whether the code meets the requirements. It does not say
  how the code meets them.
- Keep each doc short, about 250 lines. When you touch a doc that passes
  the target, split it into linked pages in the same change.
- When a protocol doc that you touch still names code or describes
  mechanics, move that content to its home in the same change.
- The documentation milestone of every plan writes the requirements and
  the decisions for the work that follows. It comes directly after the
  mockup milestone, or first when the plan has no mockup work. See the
  `plans` skill.
- When a bug reaches a review or production, check whether a requirement
  was missing or unclear. Propose the missing or clearer requirement as a
  decision with the other decisions of the task. After the user chooses the
  requirement, update the doc in the same change as the fix.

## Protocol docs change with the behaviour

Protocol docs describe the current requirements. They are not fixed rules.

- A change that keeps the behaviour at the boundary needs no protocol doc
  change, however much the code changes.
- A change to the behaviour changes a requirement. Update the protocol doc
  in the same change.
- A requirement change is a decision for the user. Propose it when the
  implementation finds that a requirement is wrong or worse than an
  alternative that you recommend. Propose it also when a requirement is
  silent on a behaviour at the boundary. Use the layout of the
  `decisions-and-findings` skill, with the other decisions of the task. Do
  everything that does not depend on it first. Until the user answers,
  change neither the behaviour nor the doc.
- A detail that a requirement settles but does not spell out is not a
  gap. Apply the decision test in the `decisions-and-findings` skill.
  Make and record the call as the test says.
- When the code and a protocol doc disagree, do not assume that the doc is
  right. Decide on the merits which side is right, then change the other
  side to match it.
- Do not drop an option, rank it lower, or recommend a different option
  only because it conflicts with a protocol doc. Include the doc update in
  that option and in its effort.
- The decision and safety rules still apply. The decision test in the
  `decisions-and-findings` skill and the deletion audit in the `git-commit`
  skill send some options to the user. Recommend such an option on its
  merits, and let the user decide.

## Behaviour that is not built yet

A doc that reaches `main` before its behaviour starts with a status line.
Read [references/status-lines.md](references/status-lines.md) before you
add, change, or remove one.

- Remove the status line in the change that builds its behaviour.
- Before you delete a plan or a follow-up item, find each status line that
  links it. Remove the line when its behaviour is built. Otherwise link it
  to the item that will build the rest.

---
name: documentation
description: Rules for README files, the docs directory, and protocol docs, which are the spec and change with the implementation. Use before you edit a README.md, a Rust crate README, anything under docs/, or a protocol doc, whenever a code change could leave a doc stale, and when a change or a review option conflicts with a protocol doc. Covers README structure, the required crate README sections, consistency and completeness rules for docs, protocol doc length, markers for planned behaviour that a later milestone implements, protocol docs as a record of the current design rather than fixed rules, and keeping docs aligned in the same change.
---

# Documentation

Docs under `docs/`, protocol docs, mockups, and every `README.md` are part
of the spec. Keep them aligned with the implementation in the same change.
When a change removes or renames anything, search `docs/`, `plans/`, and
every `README.md` for its name; see the `git-commit` skill.
Mockups have their own rules in the `mockups` skill.

## Workspace README

- A summary of the key features of the project, not a long list of every
  feature.
- User-facing interface documentation: CLI, API, and similar.
- Developer get-started steps.
- Key code jumping-in points.
- Links to the protocol docs and to the `plans/` directory.

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
- For binary crates or user-facing tools, document the CLI or external
  interface, not only the internal architecture.
- Keep examples aligned with the real public API and current behaviour. Do
  not describe internals that callers cannot use directly.
- Keep crate READMEs concise and high-signal: main use cases and
  boundaries, not every file or minor feature.
- When a crate has important neighbouring crates, name them and explain the
  boundary so that ownership is clear.

## Docs (`docs/`)

- Docs are kept up to date with the implementation at all times.
- A gap found in the docs during implementation is fixed in the protocol
  docs as part of the change.
- Docs are consistent with themselves: no conflicting statements.
- Docs cover the entire implementation: no guesswork is needed.
- Every code change prompts the question whether a doc could be clarified
  or enhanced.
- Docs may be nested in multiple directories.

## Protocol docs (`docs/protocol`), the specs

- Protocol docs define the contract between the spec and the code.
- They are as detailed as possible and complete: no guesswork is needed
  during implementation.
- They stay aligned with the implementation. If there is a bug in the code,
  review whether the spec needed to be better defined.
- Keep each doc short, about 250 lines. Split a doc that grows past that
  into linked pages.
- The first milestone of every plan updates the protocol docs so that they
  define the complete contract before implementation starts; see the
  `plans` skill.
- Add a marker to protocol doc text that describes behaviour that a later
  milestone implements. The marker is a short note that links to the plan
  and names the milestone. It lets readers tell planned behaviour from
  implemented behaviour.
- When the plan moves the behaviour to another milestone or renumbers that
  milestone, update the marker.
- Remove the marker in the milestone that implements the behaviour, in the
  same change as the code. Before you mark a milestone completed, search
  the protocol docs for markers that link to its plan.

## Protocol docs change with the implementation

Protocol docs are detailed, so they record implementation details as well
as the contract. They describe the current design. They are not fixed
rules: change them as the implementation develops, and keep them aligned
with the code in the same change.

- When the implementation finds a better design than a protocol doc
  describes, use the better design and update the doc. Do not keep a
  weaker design only because a doc describes it.
- When the code and a protocol doc disagree, do not assume that the doc is
  right. Decide on the merits which side is right, then change the other
  side to match it.
- Do not drop an option, rank it lower, or recommend a different option
  only because it conflicts with a protocol doc. Include the doc update in
  that option and in its effort.
- The decision and safety rules still apply. The review-fix rule in the
  `implementation-review` skill and the deletion audit in the `git-commit`
  skill send some options to the user. Recommend such an option on its
  merits, and let the user decide.

---
name: models
description: Use before you choose an agent, a model, or an effort for delegated work, create a Conductor workspace, session, or routine, start a subagent or a reviewer, or when a skill, a plan, or a message names an action such as brainstorming, orchestrator, implementor, review agent, or wake routine.
---

# Models

One table defines the agent, the model, and the effort of each action. A
skill, a plan, or a message names the action, for example "the
`brainstorming` model" or "the `non-ui implementor` action". It never
names a model id. When a model changes, this table changes and nothing
else does.

## Actions

| Action | Agent | Model | Effort | Use |
| --- | --- | --- | --- | --- |
| `brainstorming` | claude | `fable-5-1` | `max` | Goal reviews, design options, and candidate changes before a plan exists. |
| `default orchestrator` | claude | `opus-5-5-1m` | `max` | The first session of a workspace. It plans, delegates the milestones, checks the delegated work, and reports. |
| `non-ui implementor` | codex | `gpt-6.1-sol` | `max` | Code that is not UI: backend, scripts, tests, and tooling. |
| `ui implementor` | claude | `opus-5-5-1m` | `max` | Screens, components, styles, and mockups. |
| `docs implementor` | claude | `opus-5-5-1m` | `max` | Docs, protocol docs, READMEs, and plans. |
| `first-pass review agent` | codex | `gpt-6-astra` | `max` | The implementation review and plan reviews. |
| `second-pass review agent` | claude | `fable-5-1` | `max` | The validity check, the options check, and investigations of a decision or a review item. |
| `wake routine` | claude | `haiku-5-5-1m` | `low` | The hourly routine that wakes a section coordinator. It runs a few commands. |

Every action except `wake routine` runs at max thinking. The model ids
are the ids that `conductor model` lists. When `conductor model` does not
list a model of this table, the table is stale: tell the user, and use
the nearest model that it lists.

An override for one section lives in the coordinator's state file, as
the `conductor-section-workspace-coordinator` skill says. An override
for one task lives in the user's message. Nothing else overrides the
table.

## Routes

Work that becomes an implementation or a pull request gets its own
Conductor workspace. Its first session is the orchestrator of that work.
Everything else, such as a review, an investigation, or a brainstorm,
runs where the orchestrator chooses: an in-session subagent, or a
session in the same workspace. A Codex action always needs a session or
a workspace, because a subagent runs Claude models only.

- A Conductor workspace: `conductor workspace create --agent <agent>
  --model <model> --effort <effort>`, with `--name` and `--message-file`.
- A Conductor session in an existing workspace: `conductor session create
  --workspace <id> --agent <agent> --model <model> --effort <effort>`,
  with `--name` and `--message-file`. It shares the files and the branch
  of that workspace. The report of the session is its last message:
  `conductor --json session message <id>`.
- An in-session subagent, the Agent tool of Claude Code: Claude actions
  only. Name the model by its family, `fable`, `opus`, or `haiku`, and
  pass the effort. It ends with its parent session.
- A Conductor routine: `conductor routine create --agent <agent> --model
  <model> --effort <effort>`. Routine commands need a user API key.

Give each delegation the goal, the constraints, the files to avoid, and
the report that you expect. Read the report and check the work before
you use it.

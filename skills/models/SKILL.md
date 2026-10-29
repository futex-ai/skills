---
name: models
description: Use before you choose an agent, a model, or an effort for delegated work, or create a Conductor workspace, session, routine, subagent, or reviewer. Use also when a skill, a plan, or a message names an action such as brainstorming, orchestrator, implementor, review agent, or wake routine.
---

# Models

One table defines the agent, the model, and the effort of each action. A
skill, a plan, or a message names the action, for example "the
`brainstorming` action" or "the `non-ui implementor` action". It never
names a model id. When a model changes, this table changes and nothing
else does.

## Actions

| Action | Agent | Model | Effort | Use |
| --- | --- | --- | --- | --- |
| `brainstorming` | claude | `fable-5-1` | `max` | Goal reviews, design options, and candidate changes before a plan exists. |
| `default orchestrator` | claude | `opus-5-5-1m` | `max` | The session that manages a workspace. It plans, delegates the milestones, checks the delegated work, and reports. |
| `non-ui implementor` | codex | `gpt-6.1-sol` | `max` | Code that is not UI: backend, scripts, tests, and tooling. |
| `ui implementor` | claude | `opus-5-5-1m` | `max` | Screens, components, styles, and mockups. |
| `docs implementor` | claude | `opus-5-5-1m` | `max` | Docs, protocol docs, READMEs, and plans. |
| `first-pass review agent` | codex | `gpt-6.1-sol` | `max` | The implementation review and plan reviews. |
| `second-pass review agent` | claude | `opus-5-5-1m` | `max` | The validity check, the options check, and investigations of a decision or a review item. |
| `wake routine` | claude | `haiku-5-5-1m` | `low` | The hourly routine that wakes a section coordinator. It runs a few commands. |

Every action except `wake routine` runs at max thinking. The model ids
are the ids that `conductor model` lists. When `conductor model` does not
list a model of this table, the table is stale. Tell the user, and use
the nearest model that it lists.

An override for one section lives in the coordinator's state file, as
the `conductor-section-workspace-coordinator` skill says. An override
for one task lives in the user's message. Nothing else overrides the
table.

## Routes

Each separate change, one that becomes its own pull request, gets its
own Conductor workspace. Its first session is the orchestrator of that
change. The implementors of the change run where the orchestrator
chooses: an in-session subagent, or a session in the same workspace.
Its reviews, investigations, and brainstorms run there too. A Codex action always
needs a session or a workspace, because a subagent runs Claude models
only.

Each workspace runs on its own machine with eight CPUs, so a second
workspace adds compute. Split work into workspaces to run more of it in
parallel, or when it needs that compute. Do not split for its own sake.

- A Conductor workspace: `conductor workspace create --agent <agent>
  --model <model> --effort <effort>`, with `--name` and `--message-file`.
  Add `--project-id <id>` outside a workspace of that project. Inside
  one, the current project is the default.
- A Conductor session in an existing workspace: `conductor session create
  --workspace <id> --agent <agent> --model <model> --effort <effort>`,
  with `--name` and `--message-file`. It shares the files and the branch
  of that workspace. The report of the session is its last message:
  `conductor --json session message <id>`.
- An in-session subagent, the Agent tool of Claude Code: Claude actions
  only. Name the model by its family, `fable`, `opus`, or `haiku`, and
  pass the effort. It ends with its parent session.
- A Conductor routine: `conductor routine create --name <name>
  --project-id <id> --agent <agent> --model <model> --effort <effort>
  --prompt-file <path>`. Routine commands need a user API key.

Give each delegation the goal, the constraints, the files to avoid, and
the report that you expect. Read the report and check the work before
you use it.

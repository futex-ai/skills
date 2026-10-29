---
name: models
description: Use before you delegate work, choose an agent, a model, or an effort, create a Conductor workspace, session, or routine, or start a subagent or a reviewer, and when a skill, a plan, or a message names an action such as brainstorming, orchestrator, implementor, or review agent.
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
| `brainstorming` | claude | `opus-5-5-1m` | `max` | Goal reviews, design options, and candidate changes before a plan exists. |
| `default orchestrator` | claude | `opus-5-5-1m` | `max` | The session that manages a workspace. It plans, delegates the milestones, checks the delegated work, and reports. |
| `non-ui implementor` | codex | `gpt-6.1-sol` | `max` | Code that is not UI: backend, scripts, tests, and tooling. |
| `ui implementor` | claude | `opus-5-5-1m` | `max` | Screens, components, styles, and mockups. |
| `docs implementor` | claude | `opus-5-5-1m` | `max` | Docs, protocol docs, READMEs, and plans. |
| `first-pass review agent` | codex | `gpt-6.1-sol` | `max` | The implementation review and plan reviews. |
| `second-pass review agent` | claude | `opus-5-5-1m` | `max` | The finding checks of a review, the options check of plan decisions, and investigations of a decision or a review item. |

Every action runs at the `max` effort. The model ids are the ids that
`conductor model` lists. When `conductor model` does not list a model of
this table, the table is stale. Tell the user. Then use the nearest
model that it lists.

The user can override an action for one task in a message. Nothing else
overrides the table.

## Routes

Work that becomes an implementation or a pull request gets its own
Conductor workspace. Its first session runs the `default orchestrator`
action. That session runs the other actions of the work inside the
workspace. Each runs as an in-session subagent or as a session in the
same workspace. The implementors of its milestones, a review, an
investigation, and a brainstorm are such actions.

Each workspace runs on its own machine, so a second workspace adds
compute. Split work into workspaces to run more of it in parallel, or
when it needs that compute. Do not split for its own sake.

- A Conductor workspace: `conductor workspace create --agent <agent>
  --model <model> --effort <effort>`, with `--name` and `--message-file`.
  Take the values from the `default orchestrator` action. Add
  `--project-id <id>` outside a workspace of that project. Inside one,
  the current project is the default.
- A Conductor session: `conductor session create --agent <agent>
  --model <model> --effort <effort>`, with `--name` and `--message-file`.
  It shares the files and the branch of its workspace. Add
  `--workspace <id>` for a workspace other than your own.
- An in-session subagent: the Agent tool of Claude Code. It runs Claude
  models only. Name the model by its family, such as `opus` or `fable`.
  Pass the effort. It ends with its parent session.
- A Conductor routine: `conductor routine create --name <name>
  --project-id <id> --agent <agent> --model <model> --effort <effort>
  --prompt-file <path>`. Routine commands need a user API key.

An action of an agent other than your own needs a Conductor session or a
workspace. For example, a Claude session runs a Codex action as a
session.

## Delegating

Give each delegation the goal, the constraints, the files to avoid, and
the report that you expect. Read the report. Check the work before you
use it.

The report of a session is the last text that its agent wrote. Wait
until `conductor session status <id>` says `idle`. Then read the
transcript with `conductor --json session message <id> --limit 100`.
The list starts with the oldest message. Step `--offset` until `hasMore`
is false. Take the last text of the agent.

## Checklist

- [ ] The delegation names an action from the table, not a model id.
- [ ] The command or the Agent tool call passes the agent, the model, and
      the effort of that action.
- [ ] Work that becomes an implementation or a pull request runs in its
      own workspace. Its first session runs the `default orchestrator`
      action.
- [ ] You read the report. You checked the work before you used it.

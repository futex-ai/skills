---
name: models
description: Use before you delegate work, start a subagent or a reviewer, or choose an agent, a model, or an effort, and when a skill, a plan, or a message names an action such as brainstorming, orchestrator, implementor, or review agent.
---

# Models

One table defines the agent, the model, and the effort of each action. A
skill, a plan, or a message names the action, for example "the
`brainstorming` action" or "the `non-ui implementor` action". It never
names a model id. When a model changes, this table changes and nothing
else does. The `delegating` skill says where and how each action runs.

## Actions

| Action | Agent | Model | Effort | Use |
| --- | --- | --- | --- | --- |
| `brainstorming` | claude | `opus-5-5-1m` | `max` | Goal reviews, design options, and candidate changes before a plan exists. |
| `default orchestrator` | claude | `opus-5-5-1m` | `max` | The session that manages a workspace. It plans, delegates the milestones, checks the delegated work, and reports. |
| `non-ui implementor` | codex | `gpt-6.1-sol` | `max` | Code that is not UI: backend, scripts, tests, and tooling. |
| `ui implementor` | claude | `opus-5-5-1m` | `max` | Screens, components, styles, and mockups. |
| `docs implementor` | claude | `opus-5-5-1m` | `max` | Docs, protocol docs, READMEs, and plans. |
| `first-pass review agent` | codex | `gpt-6.1-sol` | `max` | The implementation review and plan reviews. |
| `second-pass review agent` | claude | `opus-5-5-1m` | `max` | The finding checks of a review, the options check of plan decisions and brainstorm items, and investigations of a decision or a review item. |

Every action runs at the `max` effort. The model ids are the ids that
`conductor model` lists. When `conductor model` does not list a model of
this table, the table is stale. Tell the user. Then use the nearest
model that it lists.

The user can override an action for one task in a message. Nothing else
overrides the table.

## Checklist

- [ ] The delegation names an action from the table, not a model id.
- [ ] The command or the Agent tool call passes the agent, the model, and
      the effort of that action.

# Coordinator state: <section name>

Section `<section id>`. Workspace `<workspace id>`. Project `<project id>`.
Repository `<owner/repo>`. Merge method: <squash, or the method that
`AGENTS.md` names>.

Routine: <not checked | waiting for the user since <date> | created on
<date>, trigger waiting for the user | confirmed on <date>>.

## Goals and metrics

- <date>: <one goal or metric, as the user gave it. Add the current value
  and the target when the user gave them.>
- None. <Keep this line only when the user gave no goal.>

## Actions

The `models` skill defines the model of each action. Overrides for this
section, as the user gave them:

- None. <Or: <date>: <action>: <agent, model, effort>.>

## Board

| Workspace | Name | Orchestrator | Branch or PR | Stage | Next action | Updated |
| --- | --- | --- | --- | --- | --- | --- |
| <id> | <name> | <orchestrator session id> | <branch, or PR #n> | <stage> | <what the next cycle does, and what it waits for> | <date> |

Stages: new, planning, implementing, review, merge, done, blocked.

## Escalations

- <date>: <workspace>: <item number and title>. Blocks: <what>. Asked in
  the status report on <date>.

## Backlog

- <candidate change from a goal review: title, expected effect, effort,
  areas, and why it waits>.
- <follow-up: the larger fix that a decision deferred, the workspace and
  the item number, and its effort>.

## Log

- <date time>: <one line: what this cycle changed>.

Keep the last 30 log lines. Drop a `done` board line after one week.

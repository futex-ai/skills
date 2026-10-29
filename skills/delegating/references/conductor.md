# Route commands

This file gives the command of each route in the skill, and how to read
the report of a session. Conductor runs each workspace on its own cloud
machine. It creates the workspace branch from the base branch that you
name, and it starts the first session with the prompt. The syntax comes
from `conductor --help`. The procedure around these commands is in
[workspaces.md](workspaces.md).

## Workspace

```sh
conductor workspace create --branch <primary-branch> \
  --name "<plan-name>: <item>" --agent <agent> --model <model> \
  --effort <effort> --message-file .context/<plan-name>/prompts/<item>.md
conductor workspace session <workspaceId>
conductor workspace status <workspaceId>
```

Take `--agent`, `--model`, and `--effort` from the
`default orchestrator` action in the `models` skill. The first session
is the orchestrator of the workspace. It delegates the item to the
action that the prompt names. `--branch` names the branch that the
workspace starts from. For a work item of a plan, it is the primary
branch.

Conductor names the workspace branch from the workspace name. Record
the workspace id from the output, or from `workspace list --mine`.
`workspace session` gives the session id, and `workspace status` shows
when the machine is ready. Inside a Conductor workspace,
`workspace create` defaults to the current project. Outside one, add
`--project-id <id>`.

## Session

```sh
conductor session create --agent <agent> --model <model> \
  --effort <effort> --name "<task>" --message-file <path>
```

A session runs in a workspace and shares its files and its branch. Take
the values from the action of the task. Add `--workspace <id>` for a
workspace other than your own.

To review a work item, start the session in the workspace of the item,
with the values of the `first-pass review agent` action. That workspace
has the item's branch checked out. Start the validity check and the
options check in the same way, with the `second-pass review agent`
action.

## Subagent

A subagent is the Agent tool of Claude Code. It runs Claude models only.
Name the model by its family, such as `opus` or `fable`. Pass the effort
of the action. The subagent ends with its parent session.

## Routine

```sh
conductor routine create --name <name> --project-id <id> \
  --agent <agent> --model <model> --effort <effort> --prompt-file <path>
```

A routine runs when its webhook URL is called. Routine commands need a
user API key.

## Read, message, and archive

```sh
conductor session status <sessionId>
conductor --json session message <sessionId> --limit 100
conductor message create --session <sessionId> --message-file <path>
conductor workspace archive <workspaceId>
```

The report of a session is the last text that its agent wrote. Wait
until `session status` says `idle`. Then read the transcript. The list
starts with the oldest message. Step `--offset` until `hasMore` is false.
Take the last text of the agent.

`message create` sends the fix request to the first session of the
workspace. `workspace archive` closes the machine at the close step of
the procedure, also for the primary workspace.

# Conductor

Conductor runs each workspace on its own cloud machine. It creates the
workspace branch from the base branch that the orchestrator names, and
it starts the first session with the prompt. The syntax below comes
from `conductor --help`. The procedure around these commands is in
[workspaces.md](workspaces.md).

## Create a workspace

```sh
conductor workspace create --branch <primary-branch> \
  --name "<plan-name>: <item>" --agent <agent> --model <model> \
  --effort <effort> --message-file .context/<plan-name>/prompts/<item>.md
conductor workspace session <workspaceId>
conductor workspace status <workspaceId>
```

Conductor names the workspace branch from the workspace name. Record
the workspace id from the output, or from `workspace list --mine`.
`workspace session` gives the session id, and `workspace status` shows
when the machine is ready. Inside a Conductor workspace,
`workspace create` defaults to the current project. Outside one, add
`--project-id <id>`.

## Agents and models

Take `--agent`, `--model`, and `--effort` from the
`default orchestrator` action in the `models` skill. The first session
is the orchestrator of the workspace. It delegates the item to the
action that the prompt names.

## Review a work item

```sh
conductor session create --workspace <workspaceId> --agent <agent> \
  --model <model> --effort <effort> --name "review: <item>" \
  --message-file .context/<plan-name>/prompts/review-<item>.md
```

Take the values from the `first-pass review agent` action. The session
runs in the workspace of the item. That workspace has the item's branch
checked out. Start the validity check and the options check in the same
way, with the `second-pass review agent` action.

## Read, message, and archive

```sh
conductor message create --session <sessionId> --message-file <path>
conductor workspace archive <workspaceId>
```

Read the report of a session as the `models` skill says.
`message create` sends the fix request to the first session of the
workspace. `workspace archive` closes the machine at the close step of
the procedure, also for the primary workspace.

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
action that the prompt names. `conductor model` lists the ids that
Conductor accepts now.

## Read, message, and archive

```sh
conductor session status <sessionId>
conductor session message <sessionId> --after <messageId>
conductor message create --session <sessionId> --message-file <path>
conductor workspace archive <workspaceId>
```

`session status` says whether the agent still runs. `session message`
lists the transcript after a message id. `message create` sends the fix
request. `workspace archive` closes the machine at the close step of
the procedure, also for the primary workspace.

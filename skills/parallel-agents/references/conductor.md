# Conductor

Conductor runs each workspace on its own cloud machine, with the branch
and the first session that the orchestrator asks for. The syntax below
comes from `conductor --help`. The procedure around these commands is in
[workspaces.md](workspaces.md).

## Create a workspace

```sh
conductor workspace create --branch <primary-branch> \
  --name "<plan-name>: <item>" --agent <agent> --model <model> \
  --effort max --message-file .context/<plan-name>/prompts/<item>.md
conductor workspace session <workspaceId>
conductor workspace status <workspaceId>
```

The workspace starts on the primary branch, and its first session gets
the prompt. Conductor creates the branch for the workspace from its
name. The output gives the workspace id. `workspace session` gives the
session id, and `workspace status` shows when the machine is ready.
Inside a workspace, the command defaults to the current project.

## Agents and models

| Model | Agent | Model id |
| --- | --- | --- |
| Fable 5.1 | `claude` | `fable-5-1` |
| Opus 5.5 | `claude` | `opus-5-5-1m` |
| Astra 6 | `codex` | `gpt-6-astra` |
| Sol 6.1 | `codex` | `gpt-6.1-sol` |

`conductor model` lists the current ids and the favourites. Both agents
take `--effort max`.

## Read, message, and archive

```sh
conductor session status <sessionId>
conductor session message <sessionId> --after <messageId>
conductor message create --session <sessionId> --message-file <path>
conductor workspace archive <workspaceId>
```

`session status` says whether the agent still runs. `session message`
lists the transcript after a message id. `message create` sends the fix
request. `workspace archive` closes the machine after the merge is
pushed, or after the user agrees to abandon the item. Archive the
primary workspace with the same command after the primary pull request
merges.

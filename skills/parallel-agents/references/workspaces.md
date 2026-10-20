# Workspaces in Conductor

The orchestrator runs these commands from the primary workspace. The
syntax comes from `conductor --help`. Record every id in the ledger under
`.context/<plan-name>/workspaces.md`.

## Create a workspace for one work item

```sh
conductor workspace create --branch <primary-branch> \
  --name "<plan-name>: <item>" --agent <agent> --model <model> \
  --effort max --message-file .context/<plan-name>/prompts/<item>.md
```

The workspace starts on the primary branch, and its first session gets
the prompt. Record the workspace id from the output.
`conductor workspace session <workspaceId>` gives the session id, and
`conductor workspace status <workspaceId>` shows when the machine is
ready. A new workspace gets the skills from the repository's setup
script. Codex has no update hook, so that script runs the update script
before the install script.

## Agents and models

| Model | Agent | Model id |
| --- | --- | --- |
| Fable 5.1 | `claude` | `fable-5-1` |
| Opus 5.5 | `claude` | `opus-5-5-1m` |
| Astra 6 | `codex` | `gpt-6-astra` |
| Sol 6.1 | `codex` | `gpt-6.1-sol` |

`conductor model` lists the current ids and the favourites. Both agents
take `--effort max`.

## Read the result and request changes

```sh
conductor session status <sessionId>
conductor session message <sessionId> --after <messageId>
conductor message create --session <sessionId> --message-file <path>
```

The agent reports in its session. Read its final report and its pull
request, not the whole transcript. Send a fix request as one message
with the numbered findings and the option to apply for each.

## Integrate and close

```sh
git fetch origin <branch>
git merge --no-ff origin/<branch>
conductor workspace archive <workspaceId>
```

Run the merge on the primary branch. Directly after the merge commit,
run the merge audit from the `git-merge` skill. Archive the workspace
after the merge is pushed.

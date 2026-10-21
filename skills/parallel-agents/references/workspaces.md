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
the prompt. Record the workspace id from the output. Conductor creates
the branch for the workspace from its name. Record the branch that the
agent reports.
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

The agent reports in its session. Read its first message for the
branch, then its final report and its pull request, not the whole
transcript. Send a fix request as one message with the numbered findings
and the option to apply for each.

## Integrate and close

```sh
git fetch origin <branch>
git merge --no-ff origin/<branch>
# run the merge audit and the complete gate first
git push origin <primary-branch>
gh pr view <number> --json state,headRefOid
git merge-base --is-ancestor <headRefOid> HEAD
# only when the state is OPEN
gh pr close <number> --comment "merged into <primary-branch> at <sha>"
git push origin --delete <branch>
conductor workspace archive <workspaceId>
```

Run the merge on the primary branch. Directly after the merge commit,
run the merge audit from the `git-merge` skill. Run the complete gate
from `AGENTS.md`, then push.

Confirm that the pull request's head commit is in the primary branch.
When it is not, or git reports an unknown commit, the branch moved after
your fetch. Fetch and merge again. GitHub may not mark a pull request
into a branch other than the default as merged. When the state stays
open, close the pull request with a comment that names the merge commit.

Delete the branch on the remote. Archive the workspace. Mark it closed in
the ledger. The merge commit keeps the content of a merged branch, so
its deletion needs no approval. The content of an abandoned branch is in
no merge, so the abandon is a decision for the user.

When the primary branch's pull request into `main` merges, update the
plan's status as the `plans` skill says. Commit that update on `main` or
on a new branch, not on the primary branch. Then delete the primary
branch and archive the primary workspace.

# Workspaces

A workspace is a checkout on its own branch, on its own machine or in
its own worktree, where one agent does one work item. Conductor is one
tool for it, and [conductor.md](conductor.md) gives its commands. A
worktree agent, a second machine, or a cloud session follows the same
procedure. A worktree agent here is a workspace agent in a worktree. It
pushes its branch and opens a pull request, unlike a worktree subagent.

The orchestrator runs the procedure from the primary workspace, on the
primary branch. It keeps the ledger under
`.context/<plan-name>/workspaces.md`, as the skill defines it.

## Start a work item

1. Write the prompt from the workspace prompt template. Save it under
   `.context/<plan-name>/prompts/<item>.md`.
2. Create the workspace on the primary branch, with the model from the
   table in the skill. Give it the prompt as its first message. When the
   tool does not create the branch, create it from the primary branch
   and name it for the item.
3. Record the workspace, its session, the model, and the branch that the
   agent reports in the ledger.

A new workspace gets the skills from the repository's setup script.
Codex has no update hook, so that script runs the update script before
the install script.

## Read the result and request changes

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
```

Run the merge on the primary branch after the fix rounds, also when
findings stay open. Directly after the merge commit, run the merge
audit from the `git-merge` skill. Run the complete gate from
`AGENTS.md`, then push.

Confirm that the pull request's head commit is in the primary branch.
When it is not, or git reports an unknown commit, the branch moved after
your fetch. Fetch and merge again. GitHub may not mark a pull request
into a branch other than the default as merged. When the state stays
open, close the pull request with a comment that names the merge commit.

Delete the branch on the remote. Archive the workspace with its tool.
Mark it closed in the ledger. The merge commit keeps the content of a
merged branch, so its deletion needs no approval. The content of an
abandoned branch is in no merge, so the abandon is a decision for the
user.

When the primary branch's pull request into `main` merges, update the
plan's status as the `plans` skill says. Commit that update on `main` or
on a new branch, not on the primary branch. Then delete the primary
branch and archive the primary workspace.

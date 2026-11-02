# The cycle in detail

This reference gives the commands and the detail of the `coordinator`
skill. `SKILL.md` gives the rules.

## Create a child

```sh
conductor --json project list --limit 100 --offset <n>
conductor --json workspace create --project-id <id> --branch main \
  --name "<change>" --agent <agent> --model <model> --effort <effort> \
  --message-file .context/coordinator/messages/<child>-1.md
```

- Find the project of the repository by its `gitRemote`. Step `--offset`
  while `hasMore` is true. Without a project, pass `--repo-url <url>`
  instead of `--project-id`.
- Take the agent, the model, and the effort from the
  `default orchestrator` action of the `models` skill. When the user
  named an agent or a model for this change, use it. Say so in the child
  prompt, and record it under the user instructions of the board.
- The command prints `workspaceId`, `sessionId`, and
  `initialMessage.messageId`. Record the three ids on the board, at the
  stage `new`.

## Send a message

```sh
conductor --json message create --session <orchestrator> \
  --message-file .context/coordinator/messages/<child>-<n>.md
```

- Write each message from `templates/messages.md` to a file under
  `.context/coordinator/messages/`.
- Record the `messageId` that the command prints as the last message of
  the child on the board.
- Send a message only when the table in `SKILL.md` allows a send. Put
  everything for the child into one message.
- Run `gh` with `--repo <owner/repo>` for a child in another repository.

## Read a result

- The reader is `scripts/last-report.sh <session-id> <message-id>`. It
  reads the session status and the whole transcript, so run it at any
  status.
- Act on each report once. A report on the same last message is old. The
  next action on the board says what you did with it.
- A final report has the labels of the final-report layout, such as
  **Changed**, **Decisions**, **Checks**, and **Open**. A question has
  numbered items with lettered options. Any other text is progress text.
- The reader reads the latest request, also one that the user typed in
  the child. When the report of a child says that the user answered one
  of its items there, mark that item closed on the board. Do not send
  the answer again.
- Give each design call of a child one line under **Decisions** in your
  report. Give each problem outside the scope of a child one line under
  **Open**.
- The `Updated` field of `conductor session status` is not the time of
  the last event. The age in the result of the reader is.
- A `waiting:` result from a workspace that slept is stale, because the
  agent sends no task list when it starts again. The same tasks on the
  board from the last cycle show it.

## Stages

At each stage, relay each new item of a report whose **Action** is
`ask the user`. The other results of the reader get the same action at
every stage, as the table in `SKILL.md` says.

| Stage | The child | On a final report or a question |
| --- | --- | --- |
| `new` | works on its first report | Root questions of a brainstorm: relay them, and set `brainstorm`. A pushed plan that waits for approval: relay it, and set `plan`. An open pull request: set `merge check`. |
| `brainstorm` | waits for the answers to its root questions | Send the answers message when the user answers. A pushed plan that waits for approval: relay it, and set `plan`. |
| `plan` | waits for the approval of its plan | When the user approves, send the plan approval message, and set `implementing`. When the user asks for changes, send them with the answers message. |
| `implementing` | implements the plan, reviews it, and opens the pull request | A report with an open pull request: set `merge check`. |
| `merge check` | has an open pull request | Run the merge check. When it passes, merge, and set `merged`. |
| `merged` | is merged and archived | Nothing. Drop the line one week after the merge. |
| `blocked` | waits for an item of the user, or for another child to merge | Check whether the blocker is gone. Then set the stage that the work needs. |

Relay a plan that waits for approval as one item. Its **Location** is the
plan file and the branch. Its options are: A, approve the plan. B,
approve it with the changes that the user names. C, stop the change.

## Errors and retries

- A refusal, a usage limit, an input limit, and a missing or revoked
  credential are blocks, as the `delegating` skill says. Raise the item
  at once, with no retry. Quote the error, and give its reset time when
  it has one. Only the user can override the action of the child.
- A session is lost when its error says that its thread or its session
  is gone, such as "thread not found". Start one session in the workspace
  of the child with `conductor session create --workspace <id>`, the
  `default orchestrator` action, and the new orchestrator prompt. Record
  its id as the orchestrator.
- Cancel a stalled session with `conductor session cancel <id>`. Then
  send the retry message.
- Send the retry message once for each other error.
- After the one retry, a new error or a request without a final report or
  a question is a failed retry. A stream disconnect, such as a
  `turn.failed` after "Reconnecting... 5/5", counts too. Raise an item.
- A child that stopped with work that is not committed gets the status
  request or the retry message. Never finish its work yourself.

## The merge check

| Condition | Read it with |
| --- | --- |
| The final report | The last report of the child. The report also gives the merge method from `AGENTS.md`. |
| The required checks | `gh pr checks <n> --required`. "no required checks reported" means that the branch has none. |
| The other checks | `gh pr checks <n> --json name,bucket,workflow`. |
| A check on `main` | `gh run list --branch main --workflow <workflow> --status completed --limit 1`, then `gh run view <run> --json jobs`. |
| Draft and merge state | `gh pr view <n> --json isDraft,mergeable,mergeStateStatus,headRefOid`. |
| The diff | `gh pr diff <n>` and `gh pr view <n> --json files`. Read every changed line. |
| The items | The relayed items on the board. |

A check fails on `main` too when its job failed in the latest completed
run of its workflow on `main`. When `main` has no completed run of that
workflow, the check did not fail on `main`.

| The merge check finds | Do this |
| --- | --- |
| A check that still runs, or the merge state `UNKNOWN` | Nothing in this cycle. |
| A report that does not say complete and reviewed, or a draft | Send the fix request. |
| A defect in the diff, or a file outside the scope of the child | Send the fix request, with the line and the fact that shows the defect. |
| A check that fails only on the branch | Send the fix request once. When the child shows a cause outside the change, in a report or after the fix request, raise an item. |
| A check that is not required and fails on `main` too | The condition holds. Name the check in the report. |
| A required check that fails on `main` too, or the merge state `BLOCKED` with no check that runs | Raise an item. |
| The merge state `DIRTY` or `BEHIND` | Send the merge-main message. |
| An open item of the change | Wait for the answer of the user. |

## Merge and after

```sh
gh pr merge <n> --squash --delete-branch --match-head-commit <headRefOid>
conductor workspace archive <workspaceId>
```

- Use the merge method that the `AGENTS.md` of the repository names, or
  `--squash`. `--match-head-commit` stops the merge when the child pushed
  after your check. Then check again in the next cycle.
- Archive the child. The archive also closes the sessions of the child.
- Send the merge-main message to each child whose pull request or plan
  touches a file that the merge changed. `gh pr view <n> --json files`
  lists the files of a pull request.
- In the report, name the follow-up items that the pull request adds.
  Its description lists them. The `finish-work` skill asks for this
  after each merge.

## A workspace that the user hands over

1. Record the workspace on the board, at the stage `new`. Take its
   repository and its name from `conductor --json workspace get <id>`.
2. Take the orchestrator session that the user names. When the user names
   none, take the first session that `conductor workspace session <id>`
   lists, and name it in the report. A workspace without an open session
   gets a new orchestrator, as "Errors and retries" says.
3. Read the session with the reader. When the table in `SKILL.md` allows
   a send, send the handover message.
4. Set the stage from its report:
   - root questions of a brainstorm: `brainstorm`,
   - a pushed plan that waits for approval: `plan`,
   - work in progress: `implementing`,
   - an open pull request: `merge check`.

## A stack of pull requests

A child can open a stack with `gh stack`: pull requests that build on
each other. Only the bottom pull request targets `main`.

- Run the merge check when the report of the child gives the whole stack.
- Merge from the bottom, one pull request at a time.
- After each merge below the top, send the stack message. Check the next
  pull request in a later cycle.
- Set `merged` and archive the child after the top pull request merges.

## The archive

- Archive a child after its merge, or when the user asks for it.
- Do not archive a child at the stage `blocked`.
- An archived workspace stays restorable. Record each archive in the log
  of the board.

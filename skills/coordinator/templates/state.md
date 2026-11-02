# Coordinator board

Coordinator session `<session id>` in workspace `<workspace id>`, started
on <date>. The `coordinator` skill reads this board at the start of each
cycle and writes it at the end. Copy every id from the command that
printed it.

## Children

| Workspace | Repository | Name | Orchestrator | Last message | Branch or PR | Stage | Next action | Updated |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| <workspace id, or "none" before the create> | <owner/repo> | <name> | <session id of the orchestrator> | <id of the last message that you sent to it> | <branch, or #n> | <stage> | <the last result of the reader, the retry when you sent one, and what the next cycle does> | <date> |

Stages: `new`, `brainstorm`, `plan`, `implementing`, `merge check`,
`merged`, and `blocked`. The cycle reference of the skill says what each
stage means.

## Relayed items

| Number | Child | Child's number | Source report | State |
| --- | --- | --- | --- | --- |
| <your number> | <name of the child> | <the number of the child, or "own" for your own item> | <the id of the message that the report answered, and the date> | <"open", "answered <letter> on <date>", "sent in <message id>", or "closed on <date>"> |

Give a new item the next free number. Keep its number in each later
report.

## User instructions

- <date>: <an instruction that holds over cycles, in the words of the
  user. Examples: an agent or a model for one change, or a repository
  where the user merges by hand.>

## Log

- <date and time>: <one line: what this cycle changed.>

Keep the last 30 log lines. Drop a `merged` line, and its closed items,
one week after the merge.

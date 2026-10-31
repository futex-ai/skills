# Follow-up items

A follow-up item records work that waits until after the merge. Each item
is one file under `plans/follow-ups/`, so that parallel branches do not
conflict. [../templates/follow-up.md](../templates/follow-up.md) is the
layout.

## Adding an item

- Add an item for each of these:
  - a finding with `Action: fix after merge`
  - a finding with `Action: ask the user`
  - a blocked wider fix of a fixed finding, one item per class
  - a wider fix that the agent split off a fixed finding, one item per
    class
  - a problem that the review lists under `Outside the scope`
  - an unchecked post-merge task of a plan that the change deletes
- Name the file after the problem in concise kebab-case, for example
  `plans/follow-ups/cap-retry-loop.md`.
- Before you add an item, search `plans/follow-ups/` for the same problem.
  Update that item instead of adding a second one.
- Commit the item in the branch that finds it, so that it merges with
  that branch. The pull request description lists it.

## Writing an item

An item stands alone. A reader with only the repository and the item can
understand it, decide, and do the work. After the merge, the reader may
not have the plan, the review report, or the findings file.

- Copy every fact that the work needs into the item: the cause, the
  evidence, the requirement, and each decision that the work depends on.
  Copy a failure text, a count, or a command. Do not point to it.
- Do not depend on a plan, a review report, a findings file, a file under
  `.context/`, a pull request, a chat, or another workspace.
- In the body, do not use a number that only another document explains,
  such as "user item 104", "finding 11", "M14", or "condition 3". Say
  what it stands for. For a decision, give its choice and its date.
- Name the live files of the repository by path: code, docs, and other
  follow-up items. Say what the item needs from each file.
- The **Added** line can name the source and its finding number, as
  history. The body can end with a permalink to the source. The item must
  make sense without them.
- Write each field of the layout. When the source does not give a field,
  write it from the code and the docs. "Explaining items again" in the
  `decisions-and-findings` skill says how.
- Keep every fact of the source. When a finding check moved a finding
  outside the scope, start from its full text in the findings file, not
  from its one line.
- A flaky test gives its name, its failure text, the rerun outcome, and
  the suspected source.
- When one item covers the problem of another, merge the two items. When
  two linked items stay apart, give each a **Related** line. Name the
  other file, and say what the link means.
- Before you commit the item, read it as a reader without context. Add
  each fact that you had to look up somewhere else.

## The priority score

`scripts/follow-ups.sh` gives each item a priority score from 0 to 10.
The score adds the points of the grades on the first line of the item:

| Grade | Points |
| --- | --- |
| Severity | High 4, Medium 2, Low 0 |
| Likelihood | Rare halves the severity points. Common, or no likelihood, changes nothing. |
| Effort | Small 2, Medium 1, Large 0 |
| Confidence | High 2, Medium 1, Low 0 |
| Harder later | Yes 2, No 0 |

Severity counts most. Each other grade moves an item by one severity
grade at most. Items with the same score list High severity first, then
by path. Do not write the score in the item. The script reads the grades
each time, so the score follows each change of a grade.

The `decisions-and-findings` skill gives the scales of severity,
likelihood, and effort. Grade the other two when you write the item:

- Confidence: how sure you are that the problem is real. For a post-merge
  task, how sure you are that the task is necessary.
  - High: a test, a run, a log, or a read of the code shows the problem.
  - Medium: the code suggests the problem, but nobody reproduced it. For
    example, it needs a timing or an input that nobody ran.
  - Low: a concern that nobody checked at the code.
- Harder later: whether the fix costs more while the item waits.
  - Yes: new use adds work to the fix. Examples are records in a wrong
    stored format, callers of a wrong API or message, copies of a wrong
    pattern, and a release that users adopt.
  - No: the fix costs the same later.

When an item lacks the severity, the effort, or the confidence, the score
uses Medium for it. A missing Harder later counts as No. A grade that is
not on its scale counts as missing. A `?` after the score marks an item
with a missing grade. Add the missing grade when you next edit the item.

## Working on an item

- Work on an item only when the user asks for it.
- When the user asks for the next item, or for more than one, take the
  items in the order of `scripts/follow-ups.sh`.
- The branch that fixes an item deletes its file. Name the item in the
  commit message.
- When the user answers an item that needs a decision, apply the answer in
  a branch, and delete the item in that branch.
- When the user drops an item, delete its file.

## Listing the items

`scripts/follow-ups.sh` in the `plans` skill lists the open items,
highest priority score first. Each line gives the score out of 10, the
severity, the path, the title, and the kind. Its last line gives the
number of open items. The final report and the reminder after the merge
use that number.

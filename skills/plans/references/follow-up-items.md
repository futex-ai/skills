# Follow-up items

A follow-up item records work that waits until after the merge. Each item
is one file under `plans/follow-ups/`, so that parallel branches do not
conflict. [../templates/follow-up.md](../templates/follow-up.md) is the
layout.

## Adding an item

- Add an item for each of these:
  - a review finding with `Action: fix after merge`
  - a review finding with `Action: ask the user`
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
- Do not use a number that only another document explains, such as "user
  item 104", "finding 11", or "M14". Say what it stands for. For a
  decision, give its choice and its date.
- Name the live files of the repository by path: code, docs, and other
  follow-up items. Say what the item needs from each file.
- You can end the body with a permalink to the source, as history. The
  item must make sense without the link.
- Write each field of the layout. When the source does not give a field,
  write it from the code and the docs. "Explaining items again" in the
  `decisions-and-findings` skill says how. Add "(estimate)" after each
  judgment that no review gave, also after the severity and the effort.
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

## Working on an item

- Work on an item only when the user asks for it.
- The branch that fixes an item deletes its file. Name the item in the
  commit message.
- When the user answers an item that needs a decision, apply the answer in
  a branch, and delete the item in that branch.
- When the user drops an item, delete its file.

## Listing the items

`scripts/follow-ups.sh` in the `plans` skill lists the open items, High
severity first. Its last line gives the number of open items. The final
report and the reminder after the merge use that number.

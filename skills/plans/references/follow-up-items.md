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
  - a problem that the review lists under `Outside the scope`
  - an unchecked post-merge task of a plan that the change deletes
- Name the file after the problem in concise kebab-case, for example
  `plans/follow-ups/cap-retry-loop.md`.
- Before you add an item, search `plans/follow-ups/` for the same problem.
  Update that item instead of adding a second one.
- Commit the item in the branch that finds it, so that it merges with
  that branch. The pull request description lists it.

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

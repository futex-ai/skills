---
name: git-merge
description: The merge and rebase procedure that preserves everything already on origin/main. Use before you merge or rebase a branch, when you resolve conflicts, and directly after you commit a merge. Covers the pre-integration audit from the source tip, path-by-path conflict resolution, the two-parent check, the remerge diff review, restoring lost content, and justifying intentional merge decisions.
---

# Git merge

Do not delete or override anything already on `origin/main`, including
code, APIs, tests, docs, mockups, plans, migrations, and schema, without
explicit user approval. Passing CI does not prove preservation. The checks
around an ordinary commit are in the `git-commit` skill.

## Before integration

Fetch main and audit its additions from the source tip. Capture the tip
before you merge or rebase; never recalculate it from a rebased `HEAD`. When
you merge into main, use the other branch's tip.

```sh
git fetch origin main
source_tip=$(git rev-parse HEAD)
base=$(git merge-base "$source_tip" origin/main)
git diff --name-status "$base"..origin/main
```

Every path in that list is content the merge must keep.

## Resolving conflicts

- Resolve conflicts path-by-path. Never bulk-take `--ours` or `--theirs`
  for a tree, directory, or feature.
- Merge one branch at a time; Git skips remerge diffs for octopus merges.
- Verify the worktree before you say a merge is complete.

## After each merge commit

Directly after you commit each merge, before another commit, run
`scripts/audit-merge.sh`. It confirms the merge has exactly two parents and
prints the remerge diff. Stop if the parent check fails. Then review every
listed path:

```sh
merge=$(git rev-parse HEAD)
git show --remerge-diff "$merge" -- <path>   # repeat for every listed path
git diff "$merge" HEAD                       # commits made after the merge
```

The remerge diff shows conflict resolutions, edits to one-sided files,
undone changes, and deletions. Restore lost content before you push with
`git commit --amend`, which keeps both parents, then review the merge again.
After a push, use a follow-up commit.

## Justifying decisions

Justify each intentional decision in the PR description and name every path
it affects. If no PR exists yet, save the justifications under
`.context/<plan-name>/`, name that file in the active plan milestone, and
copy them into the PR description when it opens.

## Before the push

Run the deletion audit and the other checks in the `git-commit` skill.

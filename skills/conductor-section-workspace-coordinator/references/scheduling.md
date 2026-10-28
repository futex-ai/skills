# Scheduling and conflicts

The coordinator schedules the work so that independent changes run in
parallel, dependent changes run in order, and no two active branches edit
the same files. A pull request that drifts far from `main` costs a merge
with conflicts and a second review. So each change stays small and merges
within a day or two of its plan.

## Before a new workspace

1. Name the areas that the change will touch: packages, directories, or
   files, from the goal and a read of the repository.
2. List the open pull requests of the repository with their files:
   `gh pr list --state open --json number,title,headRefName,files,updatedAt`.
   An open pull request that touches the same files is a conflict.
3. List the active workspaces of the project with
   `conductor --json project workspace <project id> --limit 100`, and
   page with `--offset`. A workspace outside this section whose name
   points at the same area is a possible conflict. Its branch has no pull
   request yet, so ask.
4. For each possible conflict in another section, send its coordinator
   the coordination message from `templates/messages.md`. Coordinator
   workspaces are named `coordinator: <section>`. Send to their session
   named `coordinator`. Agree on an order: one goes first, and the other
   starts after that pull request merges, or starts now and avoids the
   shared files.
5. For a conflict inside this section, sequence the work: start the
   second change after the first merges, or make it a milestone of the
   first plan.
6. Record the areas and the agreed order on the board line of the new
   workspace.

## Parallel, sequence, or stack

| The changes | Schedule |
| --- | --- |
| Touch different areas | Parallel: one workspace each, started in the same cycle. |
| Touch the same files | Sequence: the second starts after the first merges. |
| Depend on each other, and each leaves the product working | One workspace, one plan, and one pull request per milestone as a stack with `gh stack`. |
| One large change with an unclear design | One workspace with the `complex` role. Plan first. Split by the plan review when it can be. |

## Keep branches close to main

- Merge the ready pull requests at the start of each cycle.
- A plan whose implementation would take more than a few days splits into
  smaller plans or a stack.
- When a merge changes files that an active branch also changes, send
  that workspace the merge-main message in the same cycle.
- Keep one active change per area.

## When there is nothing to do

A board with no active work has every stage at `done`, or at `blocked`
on the user. Then:

1. When the state records goals or metrics, create a workspace
   `review: <goal>` with the `default` role and the goal-review message.
   The reviewer measures the metric, finds the opportunities, and
   proposes up to five candidate changes with the expected effect, the
   effort, the areas, and the risks. It changes nothing.
2. Read its report. Order the candidates by expected effect per effort.
   Drop a candidate that conflicts with active work or that a reserved
   choice blocks. Start a plan workspace for each candidate that can run
   in parallel, and sequence the rest.
3. Record the candidates that you did not start under **Backlog** in the
   state file, so that a later cycle can start them. Start from the
   backlog before you start a new goal review.
4. Without a goal, end the cycle. Say in the status report that the
   section has no work and no goal.

Do not start a goal review while one runs. When the last goal review
found nothing, wait a day before the next one.

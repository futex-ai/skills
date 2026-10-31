# Scheduling and conflicts

The coordinator schedules the work so that independent changes run in
parallel and dependent changes run in order. No two active branches edit
the same files. A pull request that drifts far from `main` costs a merge
with conflicts and a second review. So each change stays small and merges
within a day or two of its plan.

## Before a new workspace

1. Name the areas that the change will touch: packages, directories, or
   files. Take them from the goal and a read of the repository.
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
   named `coordinator`. Agree on an order. One goes first. The other
   starts after that pull request merges, or starts now and avoids the
   shared files.
5. For a conflict inside this section, sequence the work. Start the
   second change after the first merges, or make it a milestone of the
   first plan.
6. Record the areas and the agreed order on the board line of the new
   workspace.

## Parallel, sequence, or stack

Each workspace has its own machine, so parallel workspaces add compute.
Split work only to run more of it in parallel. Use the independence test
of the `delegating` skill.

| The changes | Schedule |
| --- | --- |
| Touch different areas | Parallel: one workspace each, started in the same cycle. |
| Touch the same files | Sequence: the second starts after the first merges. |
| Depend on each other, and each leaves the product working | One workspace, one plan, and one pull request per milestone as a stack with `gh stack`. |
| One large change with an unclear design | One workspace. It brainstorms, then plans, as the `plans` skill says. Split by the plan review when it can be. |

## Keep branches close to main

- Merge the ready pull requests at the start of each cycle.
- A plan whose implementation would take more than a few days splits into
  smaller plans or a stack.
- When a merge changes files that an active branch also changes, send
  that workspace the merge-main message in the same cycle.
- Keep one active change per area.

## Items that wait for the user

The coordinator owns the schedule and the merge. A waiting answer blocks
the work that depends on it. It does not block independent work.

1. Escalate each item whose **Action** is `ask the user`, and each
   reserved choice.
   Record the escalation under **Escalations** with the work that its
   answer blocks.
2. Decide whether the current pull request needs that answer.
   Keep the pull request blocked when the answer affects its safety or
   approved requirements. Use the grades of the `delegating` skill. A
   High or Medium item blocks only the work that depends on its code or
   contract. A Low item never blocks.
3. When the current pull request meets its approved requirements without
   the answer, defer the dependent work.
   Keep the required checks and approved plan TODOs with the current
   pull request.
   The child records the work as a follow-up item, as the `plans` skill
   says. Record it under **Backlog** too. Keep the original item open.
   Apply no option while the answer waits.
4. Tell the orchestrator which work can merge and which work waits.
   Record the reason that the current pull request can merge.
   Keep each deferred item's source report and planned follow-up in the
   state file.
5. Recheck the escalations in each cycle.
   When the user answers a deferred item, schedule its follow-up under
   the usual conflict checks. The branch that applies the answer deletes
   the follow-up item, as the `plans` skill says.
   A merged pull request does not close a deferred item.

## When there is nothing to do

A board with no active work has every stage at `done`, or at `blocked`
on the user. Then:

1. When the state records goals or metrics, start a session
   `review: <goal>` in this workspace. Give it the `brainstorming` action
   and the goal-review message. Fetch and fast-forward `main` first, so
   that the review measures the current code. The reviewer brainstorms
   as the message says, and changes nothing.
2. Read its report, then archive the session. Order the candidates by
   expected effect per effort. Drop a candidate that conflicts with
   active work or that a reserved choice blocks. Start a plan workspace
   for each candidate that can run in parallel, and sequence the rest. A
   candidate that is an open follow-up item waits until the user asks
   for it, as the `plans` skill says. Name it in the status report.
3. Record the candidates that you did not start under **Backlog** in the
   state file. A later cycle can start them. The backlog also
   holds larger fixes and deferred user items. Start from the
   backlog before you start a new goal review. A follow-up item in the
   backlog starts only after the user answers it or asks for it.
4. Without a goal, end the cycle. Say in the status report that the
   section has no work and no goal.

Do not start a goal review while one runs. When the last goal review
found nothing, wait a day before the next one.

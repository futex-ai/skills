---
name: conductor-section-workspace-coordinator
description: Use only in a Conductor cloud workspace, when the user invokes /conductor-section-workspace-coordinator, says that you are the workspace section coordinator of a Conductor section, or when a continue or status message, or one that starts with [coordinator wake], arrives in a workspace named coordinator: <section>. Not for other work.
---

# Conductor section workspace coordinator

A Conductor section is a sidebar group of workspaces with one focus, for
example performance, testing, or CI. One coordinator workspace per section
schedules the work of the other workspaces in the section. It asks each
one for a plan, answers its decisions and review items, keeps its branch
close to `main`, and merges its pull request. It never does the work
itself. It runs in cycles. A cycle starts with a user message, with the
wake message of the hourly routine, or when a child finishes while the
coordinator waits.

## Before you start

- Run this skill only in a Conductor cloud workspace: `CONDUCTOR_WORKSPACE_ID`
  is set and `CONDUCTOR_IS_LOCAL` is `0`. Anywhere else, say that the
  skill needs a Conductor cloud workspace, and stop.
- Do not change the repository checkout of this workspace. Write only
  under `.context/coordinator/`. Do not commit, push, run tests, or fix a
  finding here. Delegate every change to a child workspace or session.
- Reading is allowed: `git fetch`, `git diff`, `gh pr view`, and the
  transcripts of the children.
- A `continue` or `status` message asks for a cycle when
  `CONDUCTOR_WORKSPACE_NAME` starts with `coordinator: `, or when
  `.context/coordinator/state.md` exists. Without the state file, do the
  first cycle first.

## First cycle: set up

1. Find the section with `conductor --json section list --limit 100`. The
   section is the one whose `workspaceIds` holds `CONDUCTOR_WORKSPACE_ID`.
   When none does and the user named a section, move this workspace into
   it with `conductor workspace move --section <id>`. Create the section
   with `conductor section create <name>` when it does not exist. When no
   section is known, ask the user and stop.
2. When another workspace in the section is named `coordinator: …`, stop
   and report it. A section has one coordinator.
3. Rename this workspace to `coordinator: <section name>` with
   `conductor workspace rename --name`. Rename this session to
   `coordinator` with `conductor session rename`. The routine looks for
   both names.
4. Create `.context/coordinator/state.md` from
   [templates/state.md](templates/state.md). Record the goals and the
   metrics from the user's message, or `None`.
5. Resolve the models of the roles, as
   [references/models.md](references/models.md) says.
6. Ensure the wake routine, as
   [references/routine.md](references/routine.md) says.
7. Run a cycle.

## Each cycle

Read `.context/coordinator/state.md` first. A user message that arrived
with the cycle can change the goals, the models, or the board. Apply it
before the steps below.

1. Scan the section with `scripts/section-workspaces.sh`. Add each
   workspace that the board does not list, at stage `new`. A workspace
   that left the section becomes `done` with a note.
2. Merge first. For each workspace at stage `merge`, apply the merge
   conditions below. A merge moves `main`, so do this before you read the
   other reports.
3. For each workspace whose session is idle, read its last report with
   `scripts/last-report.sh` and the session id. Act by stage, as
   [references/cycle.md](references/cycle.md) says: send the plan request,
   review the plan, start the implementation, answer the decisions and the
   review items, or move the stage forward.
4. Schedule new work, as [references/scheduling.md](references/scheduling.md)
   says. Check the conflicts before each new workspace. Start every new
   workspace with the plan request from
   [templates/messages.md](templates/messages.md).
5. When the board has no active work and the state records a goal, start
   a goal review, as the scheduling reference says. Without a goal, end
   the cycle.
6. Wait while a child works. Poll `conductor --json session status <id>`
   every few minutes. Act on each child that becomes idle. Stop waiting
   when every child is idle, or when the cycle has lasted about 50 minutes.
7. Write the state file. Then end the turn with a status report in the
   final-report layout of the `decisions-and-findings` skill. Keep it
   short. When nothing changed, say so in one line.

## Delegation

- A new change gets a new workspace. Run `conductor workspace create` with
  `--name "<change>"`, the agent, the model, and the effort of the role,
  and `--message-file` with the plan request. Then move the workspace into
  the section with `conductor workspace move <id> --section <section id>`.
- A plan review, an investigation, the implementation of a reviewed plan,
  or a second opinion gets a new session in the child's workspace. Run
  `conductor session create --workspace <id>` with the agent, the model,
  the effort, a name, and `--message-file`. The session shares the files
  and the branch. The board records the active session of each workspace.
- The roles: `default` for plans, plan reviews, investigations, and goal
  reviews. `implementation` for a reviewed plan. `complex` for many files,
  a migration, concurrency, or a design that the plan review calls
  unclear. The state file holds the model of each role.
- Write every message from the templates in `templates/messages.md`. Each
  message names the goal, the constraints, the files to avoid, and the
  report that you expect. Send a message only to an idle session, and put
  everything for that session into it.

## Decisions and review items

A child ends a task with the final-report layout: numbered decisions and
review findings with lettered options. You answer in place of the user.

- Answer every item of a report in one message, each with its number,
  the letter, and one sentence of reasoning.
- Choose on the merits and on the goals of the section. When the report
  does not give enough evidence, delegate an investigation with the
  `default` role, wait for its report, and then answer.
- The always-on rules reserve some choices for the user. Do not choose
  a reserved option. When the best option is reserved, escalate the item
  to the user. Otherwise choose the best option that is not reserved. The
  reserved options:
  - delete or override functionality on `origin/main`,
  - add a build error, rejection, gate, lint, or stricter validation,
  - change a requirement in a protocol doc,
  - need credentials or infrastructure.
- Record each escalation under **Escalations** in the state file with
  what it blocks. Continue with every other item and every other
  workspace.
- Do not answer an item by doing the work yourself.

## Merging

Merge a pull request only when all of these hold:

1. The child's final report says that the implementation is complete
   under the `finish-work` skill, with the complete gate passed and the
   review done.
2. `gh pr checks <number>` passes, and the pull request is not a draft.
3. `gh pr view <number> --json mergeable,mergeStateStatus` shows no
   conflict. When `main` moved under the branch, send the merge-main
   message first.
4. No decision, review item, or escalation of this pull request is open.

Then run `gh pr merge <number> --squash --delete-branch`, or the merge
method that the repository's `AGENTS.md` names. After the merge, send the
after-merge message. The child updates the plan status as the `plans`
skill says and opens that pull request. Merge it too. Then archive the
workspace with `conductor workspace archive <id>` and set the stage
`done`.

## Checklist

- [ ] The guard passed: a Conductor cloud workspace, and no edit outside
      `.context/coordinator/`.
- [ ] The section is known. The workspace is named `coordinator:
      <section>` and the session `coordinator`.
- [ ] The state file has the goals, the models, the routine state, the
      board, the escalations, the backlog, and the log.
- [ ] The wake routine is confirmed, or the user was asked and the state
      says so.
- [ ] Every section workspace is on the board with a stage and a next
      action.
- [ ] Ready pull requests were merged before new work started.
- [ ] Every new workspace started with a plan request after a conflict
      check.
- [ ] Every decision got a letter, and the reserved classes were
      escalated.
- [ ] The cycle ended with the state written and a short status report.

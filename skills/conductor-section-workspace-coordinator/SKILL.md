---
name: conductor-section-workspace-coordinator
description: Use when you run in a Conductor cloud workspace and the user invokes /conductor-section-workspace-coordinator or names you the coordinator of a Conductor section. Use also when a continue, status, or [coordinator wake] message arrives in a workspace named coordinator: <section> or holding .context/coordinator/state.md. Not for other work.
---

# Conductor section workspace coordinator

A Conductor section is a sidebar group of workspaces with one focus, for
example performance, testing, or CI. One coordinator workspace per section
schedules the work of the other workspaces in the section. It asks each
one for a plan and answers its decisions and review items. It keeps each
branch close to `main`, merges the pull request, and archives the
workspace. It never does the work itself.

Each child workspace has its own orchestrator session, which plans,
implements by delegation inside its workspace, and reports. The
coordinator runs in cycles. A cycle starts with a user message, with the
wake message of the hourly routine, or when a child finishes while the
coordinator waits.

## Before you start

- Run this skill only in a Conductor cloud workspace: `CONDUCTOR_WORKSPACE_ID`
  is set and `CONDUCTOR_IS_LOCAL` is `0`. Anywhere else, say that the
  skill needs a Conductor cloud workspace, and stop.
- Do not edit, commit, or push in this checkout. Write only under
  `.context/coordinator/`. Do not run tests or fix a finding here.
  Delegate every change to a child workspace or session. The fetch and
  the fast-forward below are the only changes to the checkout.
- Reading is allowed: `git fetch`, `git diff`, `gh pr view`, and the
  transcripts of the children.
- A `continue` or `status` message asks for a cycle when
  `CONDUCTOR_WORKSPACE_NAME` starts with `coordinator: `, or when
  `.context/coordinator/state.md` exists. Without the state file, do the
  first cycle first.
- This session lives for days, and `main` moves under it. At the start
  of every cycle run `git fetch origin main` and then
  `git merge --ff-only origin/main`. You make no commits here, so the
  fast-forward always succeeds. Then every file, plan, and rule that you
  read is current. Fetch a child's branch before you read it.

## First cycle: set up

1. Find the section with `scripts/section-workspaces.sh`. It reads every
   page of the section list and prints the section whose `workspaceIds`
   holds `CONDUCTOR_WORKSPACE_ID`. When it finds none and the user named
   a section, move this workspace into it with
   `conductor workspace move --section <id>`. Create the section with
   `conductor section create <name>` when it does not exist. When no
   section is known, ask the user and stop.
2. When another workspace in the section is named `coordinator: …`, stop
   and report it. A section has one coordinator.
3. Rename this workspace with
   `conductor workspace rename --name "coordinator: <section name>"`.
   Rename this session with
   `conductor session rename $CONDUCTOR_SESSION_ID --name coordinator`.
   The routine looks for both names.
4. Create `.context/coordinator/state.md` from
   [templates/state.md](templates/state.md). Record the goals and the
   metrics from the user's message, or `None`.
5. Ensure the wake routine, as
   [references/routine.md](references/routine.md) says.
6. Run a cycle.

## Each cycle

Fetch and fast-forward `main`, then read `.context/coordinator/state.md`.
A user message that arrived with the cycle can change the goals, the
actions, or the board. Apply it before the steps below.

1. Scan the section with `scripts/section-workspaces.sh`. Add each
   workspace that the board does not list, at stage `new`. A workspace
   that left the section becomes `done` with a note.
2. Merge first. For each workspace at stage `merge`, apply the merge
   conditions below. A merge moves `main`, so do this before you read the
   other reports. Then archive each finished workspace, as the cycle
   reference says.
3. For each workspace whose session is idle, read its last report with
   `scripts/last-report.sh` and the session id. Act by stage, as
   [references/cycle.md](references/cycle.md) says. The action is the plan
   request, the plan review, the implement message, the answers to the
   items, or the next stage.
4. Schedule new work, as [references/scheduling.md](references/scheduling.md)
   says. Check the conflicts before each new workspace. Start every new
   workspace with the plan request from
   [templates/messages.md](templates/messages.md).
5. When the board has no active work and the state records a goal, start
   a goal review. The scheduling reference says how. Without a goal, end
   the cycle.
6. Wait while a child works. Poll `conductor --json session status <id>`
   every few minutes. Act on each child that becomes idle. Stop waiting
   when every child is idle, or when the cycle has lasted about 50 minutes.
7. Write the state file. Then end the turn with a status report in the
   final-report layout of the `decisions-and-findings` skill. Keep it
   short. When nothing changed, say so in one line.

## Delegation

- Name an action, never a model. The `models` skill defines the agent,
  the model, and the effort of each action. The state file records the
  overrides that the user gave for this section.
- Every change that becomes an implementation or a pull request gets its
  own workspace, as the `models` skill says. Run `conductor workspace
  create` with `--name "<change>"`, the `default orchestrator` action,
  and `--message-file` with the plan request. Then move the workspace
  into the section with `conductor workspace move <id> --section <section
  id>`. The first session is the workspace's orchestrator. It writes the
  plan. After the approval it implements every milestone by delegation
  inside its workspace, as the implement message says. It stays the
  session that you talk to.
- A plan review gets a new session in the child's workspace with the
  `first-pass review agent` action. An investigation of a decision or a
  review item gets one with the `second-pass review agent` action. Run
  `conductor session create --workspace <id>` with a name and
  `--message-file`. The session shares the files and the branch. Read its
  report, then archive it with `conductor session archive <id>`.
- A goal review gets a new session in this workspace with the
  `brainstorming` action. It produces a report, not a change, so it
  needs no workspace of its own.
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
  does not give enough evidence, delegate an investigation, wait for its
  report, and then answer.
- When a larger option is better than the recommended one, weigh two
  schedules. Take the larger fix now when it is not much larger. Take it
  too when it removes the class of problem, or when it would undo the
  smaller fix. Otherwise choose the smaller fix now, and put the larger
  fix under **Backlog** in the state file as a follow-up workspace. Say
  which schedule you chose and why.
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
skill says and opens that pull request. Merge it too. Then set the stage
`done` and archive the workspace.

## Checklist

- [ ] The guard passed: a Conductor cloud workspace, and no edit outside
      `.context/coordinator/`.
- [ ] `main` was fetched and fast-forwarded at the start of the cycle.
- [ ] The section is known. The workspace is named `coordinator:
      <section>` and the session `coordinator`.
- [ ] The state file has the goals, the action overrides, the routine
      state, the board, the escalations, the backlog, and the log.
- [ ] The wake routine is confirmed, or the user was asked and the state
      says so.
- [ ] Every section workspace is on the board with a stage and a next
      action.
- [ ] Ready pull requests were merged before new work started, and the
      finished workspaces were archived.
- [ ] Every delegation named an action from the `models` skill.
- [ ] Every new workspace started with a plan request after a conflict
      check.
- [ ] Every decision got a letter, and the reserved classes were
      escalated.
- [ ] The cycle ended with the state written and a short status report.

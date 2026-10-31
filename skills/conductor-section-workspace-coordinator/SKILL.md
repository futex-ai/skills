---
name: conductor-section-workspace-coordinator
description: "Use when you run in a Conductor cloud workspace and the user invokes /conductor-section-workspace-coordinator or names you the coordinator of a Conductor section. Use also when a continue, status, or [coordinator wake] message arrives in a workspace named coordinator: <section> or holding .context/coordinator/state.md. Not for other work."
---

# Conductor section workspace coordinator

A Conductor section is a sidebar group of workspaces with one focus, for
example performance, testing, or CI. One coordinator workspace per section
schedules the work of the other workspaces in the section. It asks each
one for a plan and answers its decisions and review items. It keeps each
branch close to `main`, merges the pull request, and archives the
workspace. It never does the work itself.

Each child workspace has one orchestrator: a session named
`orchestrator` that runs the `default orchestrator` action. It manages
its workspace. It plans, delegates the work inside the workspace, checks
the delegated work, and reports. The coordinator sends every message for
a workspace to its orchestrator, never to a helper session.

The coordinator runs in cycles. A cycle starts with a user message, with
the wake message of the hourly routine, or when a child finishes while
the coordinator waits.

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

## First cycle

Without `.context/coordinator/state.md`, set up first, as
[references/setup.md](references/setup.md) says: the section, the names,
the state file, and the wake routine. Then run a cycle.

## Each cycle

Fetch and fast-forward `main`, then read `.context/coordinator/state.md`.
A user message that arrived with the cycle can change the goals, the
actions, or the board. Apply it before the steps below.

1. Scan the section with `scripts/section-workspaces.sh`. It gives the
   orchestrator of each workspace, or the newest session when there is
   none. Add each workspace that the board does not list, at stage `new`.
   A workspace that left the section becomes `done` with a note.
2. Merge first. For each workspace at stage `merge`, apply the merge
   conditions below. A merge moves `main`, so do this before you read the
   other reports. Then archive each finished workspace, as the cycle
   reference says.
3. For each workspace, read the report of its orchestrator, and act by
   stage, as [references/cycle.md](references/cycle.md) says. The
   action is the plan request, the plan review, the implement message,
   the answers to the items, or the next stage. A workspace without an orchestrator gets one
   first, as that reference says.
4. Schedule new work, as [references/scheduling.md](references/scheduling.md)
   says. Check the conflicts before each new workspace. Start every new
   workspace with the plan request from
   [templates/messages.md](templates/messages.md).
5. When the board has no active work and the state records a goal, start
   a goal review. The scheduling reference says how. Without a goal, end
   the cycle.
6. Wait while a child works. Read its report every few minutes, and act
   when it is no longer `pending:` or `waiting:`. Stop waiting when no
   child works, or after about 50 minutes.
7. Write the state file. Then end the turn with a status report in the
   final-report layout of the `decisions-and-findings` skill. Keep it
   short. When nothing changed, say so in one line.

## Delegation

- Name an action, never a model. The `models` skill defines the agent,
  the model, and the effort of each action. The state file records the
  overrides that the user gave for this section. Every command takes its
  agent, model, and effort from that action and those overrides.
- Every change that becomes an implementation or a pull request gets its
  own workspace, as the `delegating` skill says. Create it with the
  workspace command of its Conductor reference and the
  `default orchestrator` action. Name it after the change. Add
  `--session-name orchestrator`, and give the plan request as the message
  file. Then move it into the section with
  `conductor workspace move <id> --section <section id>`. The first
  session is the workspace's orchestrator. It writes the plan. After the
  approval it implements every milestone by delegation inside its
  workspace, as the implement message says.
- A workspace that the user adds gets an orchestrator first, as the
  cycle reference says.
- A plan review gets a new session in the child's workspace with the
  `first-pass review agent` action. An investigation of an item gets one
  with the `second-pass review agent` action. Start it with the session
  command of that reference and `--workspace <id>`. The session shares
  the files and the branch. Read its report, then archive it with
  `conductor session archive <id>`.
- A goal review gets a new session in this workspace with the
  `brainstorming` action. It produces a report, not a change, so it
  needs no workspace of its own.
- Write every message from the templates in `templates/messages.md`. A
  message that starts a workspace or a session is a prompt. It has the
  six fields of the `delegating` skill, from Scope to Output. Send a
  message only when the report of that session is not `pending:` or
  `waiting:`. Put everything for that session into it.

## Decisions and review items

A child ends a task with the final report of the `decisions-and-findings`
skill. Its **Open** list holds the items that wait for an answer, each
with lettered options. You answer in place of the user.

- Answer every report item in one message. Give each chosen option its
  number, letter, and one sentence of reasoning. Mark each escalated item
  as waiting for the user.
- Escalate every item whose **Action** is `ask the user`. Keep the
  choice open until the user answers. Apply no option while that answer
  waits.
- Choose on the merits and on the goals of the section. When the report
  does not give enough evidence, delegate an investigation, wait for its
  report, and then answer.
- When a larger option is better than the recommended one, weigh two
  schedules. Take the larger fix now when it is not much larger. Take it
  too when it removes the class of problem, or when it would undo the
  smaller fix. Otherwise choose the smaller fix now. The child records
  the larger fix as a follow-up item, as the `plans` skill says. Add it
  under **Backlog** too. Say which schedule you chose and why.
- The always-on rules reserve some choices for the user. Do not choose
  a reserved option. When the best option is reserved, escalate the item
  to the user. Otherwise choose the best option that is not reserved. The
  reserved options:
  - delete or override functionality on `origin/main`,
  - add a build error, rejection, gate, lint, or stricter validation,
  - change a requirement in a protocol doc,
  - delete, skip, or weaken a test, unless the `testing` skill allows it,
  - need credentials or infrastructure.
- Record each escalation under **Escalations** in the state file with
  what it blocks. Continue with every other item and every other
  workspace.
- You own scheduling and merges. Decide which escalated work can wait,
  as [references/scheduling.md](references/scheduling.md) says.
  Deferred work can leave the current pull request ready to merge.
- Do not answer an item by doing the work yourself.

## Merging

Merge a pull request only when all of these hold:

1. The child's final report says that the implementation is complete
   under the `finish-work` skill. The checks that the skill requires
   passed: the complete gate, or the Markdown validation of a
   documentation-only or plan-only change. The review is done.
2. `gh pr checks <number>` passes, and the pull request is not a draft.
3. `gh pr view <number> --json mergeable,mergeStateStatus` shows no
   conflict. When `main` moved under the branch, send the merge-main
   message first.
4. No unanswered item blocks this pull request under the scheduling reference.
   Deferred items stay open for their follow-up pull requests.

Then run `gh pr merge <number> --squash --delete-branch`, or the merge
method that the repository's `AGENTS.md` names. In the middle of a stack,
send the stack message, as the cycle reference says. The last pull
request of the change deletes its plan, as the `plans` skill says. After
it merges, set the stage `done` and archive the workspace. In the status
report, name its follow-up items, as step 8 of `finish-work` says.

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
      action. It has a session named `orchestrator`, and every message
      went to it.
- [ ] Ready pull requests were merged before new work started, and the
      finished workspaces were archived.
- [ ] Every delegation named an action from the `models` skill. Every
      new prompt had the six fields of the `delegating` skill.
- [ ] Every new workspace started with a plan request after a conflict
      check.
- [ ] Each answered item got a letter. Each unanswered user choice stayed open.
      The state records deferred work and its merge reason.
- [ ] The cycle ended with the state written and a short status report.

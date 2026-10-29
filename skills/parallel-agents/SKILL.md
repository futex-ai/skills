---
name: parallel-agents
description: Use when you work on a plan, before you decide whether to split it across workspaces, when you have two or more independent tasks, such as failing tests in separate files, bugs in separate subsystems, or separate research questions, before you start a subagent or write its prompt, when a model blocks or rejects a request, when a delegated branch comes back, when agents would edit the same files, and when an open finding could block the next milestone.
---

# Parallel agents

A subagent is an agent with a fresh context that you start for one task
in your own session. A workspace agent works on its own machine and its
own branch. The orchestrator starts it for one work item. The
orchestrator is the session that owns the plan and the primary branch.
Neither agent sees your session. You give each the exact context that it
needs, and it returns a report.

## Independence test

Start agents in parallel only when all of these hold:

- You know the fault or the question in each task. Exploratory debugging
  is not a task yet.
- Each task is clear without the context of the other tasks.
- No task needs the result of another task.
- The tasks change different files and share no port, database, fixture,
  or build output. No test runs beside the gate.
- No task needs a view of the whole system.

When one condition fails, do not split the work. Investigate the tasks
together, or run the agents one after the other. Related failures often
share one root cause. Fix that cause first, then split what remains. A
small change in an area that another agent edits stays with you.

## The prompt

Each prompt has the fields Scope, Goal, Context, Steps, Constraints, and
Output. The templates are
[templates/subagent-prompt.md](templates/subagent-prompt.md) and
[templates/workspace-prompt.md](templates/workspace-prompt.md).

- **Scope:** the one domain. Name the files, the tests, or the question.
- **Goal:** the result that counts as done.
- **Context:** everything that the agent needs, pasted in. Give the
  errors, the test names, the paths, the commands from `AGENTS.md`, and
  the skills to read. Point to the plan, and give its decisions and what
  the earlier milestones established. Keep logs out of the plan, because
  a delegated agent reads the whole plan on every turn.
- **Steps:** the procedure, with the agent's own checks and TODO ticks.
- **Constraints:** the files that it may change, and what it must not
  do. Examples: change files outside the scope, merge `main`, increase a
  timeout, delete a test, or start the next item.
- **Output:** the report to return. Ask for the result or the root
  cause, the files changed, and the checks with their results. Ask who
  decided what, and the open questions.

A read-only agent, such as the reviewer in the `implementation-review`
skill, gets "change nothing" as its constraint.

## Actions and blocks

Name an action, never a model. The `models` skill defines the agent,
the model, the effort, and the route of each action. Delegate each task
to the action that the skill gives for its kind of work. The
orchestrator and each workspace agent run the `default orchestrator`
action. An action of another agent runs as a session in your workspace.
That session shares your working tree, so treat it as a subagent.

A block is a refusal, or a rejection that stays after one retry.
Examples: a usage limit, an input limit, or a missing or revoked
credential. A model id that `conductor model` does not list is a stale
table instead, as the `models` skill says. When an action's model
blocks a request, ask the user, with the refusal text verbatim. Only
the user can override the action, for one task.

A blocked item stays in its workspace. Its next delegate gets the
prompt and the diff so far. Do not rewrite the request to hide what it
does, and do not skip the step.

| The record says | The answer |
| --- | --- |
| "Codex rejected the generated review prompt [...] so no review findings were emitted." | Split the review by area, or ask the user with the refusal text. A missing review is not a result. |
| "retry this task when reviewer capacity resets." | Ask the user now, with the retry time. The review still runs before the merge. |
| "the cloud Codex CLI is unauthenticated (HTTP 401), so no review findings were produced." | Ask the user now, with the error text. The review is the step. The tool is not. |

## Subagents in one session

1. Group the work into domains. A domain is one test file, one
   subsystem, one bug, or one research question.
2. Write one prompt for each domain.
3. Start every subagent in the same response, so that they run in
   parallel. One call per response runs them one after the other.
4. Wait for every subagent. Do not integrate partial results.
5. Read each report and save it under `.context/<plan-name>/`. Check
   whether two agents changed the same code. Run the checks from the
   `finish-work` skill on the combined result. Only the complete gate
   proves the combined work. Spot check the changes, because agents make
   systematic errors, for example a longer timeout that hides a race.
6. Commit with the `git-commit` skill. In the final report, say what
   each agent did. Say which findings you re-checked in the code, and
   which rest on the agent's evidence.

Subagents share your working tree unless the tool gives each its own
worktree. Keep the scopes disjoint, or two subagents that edit one file
overwrite each other. In the shared tree only you commit. In its own
worktree a subagent commits on its branch with the `git-commit` skill
and does not push. Commit your own changes first. A worktree holds only
committed content. Integrate the branch with the `git-merge` skill.

## Workspaces across machines

The orchestrator splits a plan into work items. Items that pass the
independence test run at the same time, each in its own workspace. An
item that needs the compute of its own machine gets one too. The
orchestrator delegates the other items in order, inside its own workspace.

[references/workspaces.md](references/workspaces.md) gives the procedure,
and [references/conductor.md](references/conductor.md) the Conductor
commands. One real example: milestones 6a, 7, and 7a of a plan ran in
parallel Codex and Claude sessions. One combined gate verified them.

- The primary branch is the branch of the plan. Every workspace branch
  starts from it and merges from it, never from `main`. Only the primary
  branch merges `main`. Its pull request into `main` is the completion
  boundary from the `plans` skill. That pull request deletes the plan,
  as that skill says. After that merge, delete the primary branch and
  archive its workspace.
- A work item is a milestone, or a group of TODOs in one milestone that
  touches its own files. Keep the milestone order from the `plans` skill.
  Keep backend work before UI work. Fan out inside one level.
- The orchestrator plans, writes the prompts, delegates, and checks. It
  does not implement. A correction of a few lines found while you check
  is fine. Anything larger goes back to the delegate.
- Name the workspace `<plan-name>: <item>`. The tool creates the branch.
  Record the reported branch in the ledger.
- The plan file is the one shared file. A workspace adds `Branch:` and
  its branch name to the TODO lines that it owns, and it ticks only those
  lines. You resolve a plan conflict path by path at the merge.
- Keep a ledger under `.context/<plan-name>/workspaces.md`. It lists
  the item, the ids, the action, the branch, the pull request, the review
  round, and the state. Keep the prompts and the reports there too.
- The workspace agent commits with the `git-commit` skill, pushes its
  branch, and opens a pull request into the primary branch. It never
  merges. When its push fails for a missing credential, it reports the
  commit and stops.

### Check, merge, and continue

1. When a workspace reports, run the `implementation-review` skill on
   its branch against the primary branch, in that workspace. A large
   diff can split by area, with one `first-pass review agent` for each
   area. Then read the diff yourself and re-run the checks. Confirm
   every ticked TODO and the push, and run the deletion audit from the
   `git-commit` skill. Never accept the report alone.
2. Send the `fix now` findings back to the same workspace session as
   one fix request. Give the numbers, the option of each, and "do not
   start the next item". The review-fix rule allows two fix rounds. Then
   stop and merge.
3. Merge the branch into the primary branch with the `git-merge` skill.
   Run the complete gate from `AGENTS.md` on the merged tree, then push.
   Each workspace ran the gate on its own tree only. The combined gate
   proves the milestone. Then close the workspace. Confirm the merge and
   close its pull request as the workspace reference says. Delete its
   remote branch. Archive the workspace. Mark it closed in the ledger. Do
   the same for a workspace that the user agrees to abandon.

   | The record says | The answer |
   | --- | --- |
   | "[...] passed in all ten phases on the tree before the last two merges. [...] The commits after that run change only Markdown." | The gate proves the tree that it ran on. Run it on the merged tree, or name the CI run that did. |

4. Merge `main` into the primary branch before each delegation batch,
   before each branch merge, and before the final pull request.
5. Merge each branch as it finishes. An open finding never blocks the
   merge of a workspace branch. Record it as a follow-up item, as the
   `plans` skill says. Fix it after the user answers, on a route from the
   `models` skill. A branch that waits diverges. Its conflicts grow.
6. A High or Medium finding blocks only the work that depends on the
   affected code or contract. A Low finding never blocks. Every open
   finding closes before the final pull request merges, unless the user
   moves it to the post-merge follow-up section.
7. Ask the user at once for a blocking decision, and stop the dependent
   work until the answer comes. Blocking decisions are:
   - a deletion against `origin/main`,
   - a requirement change in a protocol doc,
   - an irreversible or outward-facing action,
   - a High finding with `Action: ask the user`,
   - a choice where any assumption wastes the work.
   Send the other decisions in one numbered message at the next batch
   boundary, in the layout of the `decisions-and-findings` skill.
   Continue the independent work meanwhile. An unanswered decision stays
   open, as the always-on rules say. The review-fix rule says which
   findings you fix without the user.

## Checklist

- [ ] Every parallel task passed the independence test.
- [ ] Every prompt has the six fields, from Scope to Output.
- [ ] Each workspace branch starts and merges from the primary branch.
- [ ] Delegates ran their actions. A blocked step went to the user.
- [ ] You ran the combined gate and closed each merged workspace.
- [ ] The ledger and the reports are under `.context/`, not in the plan.
- [ ] Open findings never block a workspace merge. They block dependent
      work only and close before the final pull request.

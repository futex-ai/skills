---
name: parallel-agents
description: Use when you have two or more independent tasks, such as failing tests in separate files, bugs in separate subsystems, or separate research questions, before you start a subagent or write its prompt, when you split a plan across workspaces or branches, when you choose the model for delegated work, when a model blocks or rejects a request, when a delegated branch comes back for a check or a merge, when agents would edit the same files, and when an open finding could block the next milestone.
---

# Parallel agents

A subagent is an agent with a fresh context that you start for one task
in your own session. A workspace agent is an agent on its own machine
and its own branch, started by the orchestrator for one work item. The
orchestrator is the session that owns the plan and the primary branch.
Neither agent sees your session. You give each the exact context that it
needs, and it returns a report. The same rules apply at both levels.

## Independence test

Start agents in parallel only when all of these hold:

- You know the fault or the question in each task. Exploratory debugging
  is not a task yet.
- Each task is clear without the context of the other tasks.
- No task needs the result of another task.
- The tasks change different files and use different resources, such as
  ports, databases, fixtures, and build output. No test runs beside the
  gate.
- No task needs a view of the whole system.

When one condition fails, do not split the work. Investigate the tasks
together, or run the agents one after the other. Related failures often
share one root cause. Fix that cause first, then split what remains. A
small change in an area that another agent edits stays with you.

## The prompt

Each prompt has the fields Scope, Goal, Context, Steps, Constraints, and
Output. [templates/subagent-prompt.md](templates/subagent-prompt.md) is
the template for a subagent, and
[templates/workspace-prompt.md](templates/workspace-prompt.md) for a
workspace agent.

- **Scope:** the one domain. Name the files, the tests, or the question.
- **Goal:** the result that counts as done.
- **Context:** everything that the agent needs, pasted in: the errors,
  the test names, the paths, the commands from `AGENTS.md`, and the
  skills to read. Point to the plan, and give its decisions and what the
  earlier milestones established. Keep logs out of the plan, because a
  delegated agent reads the whole plan on every turn.
- **Steps:** the procedure, the checks that the agent runs itself, and
  the TODOs that it ticks.
- **Constraints:** the files that it may change, and what it must not
  do. Examples: change files outside the scope, merge `main`, increase a
  timeout, delete a test, or start the next item.
- **Output:** the report to return. Ask for the result or the root
  cause, the files changed, the checks with their results, who decided
  what, and the open questions.

A read-only agent, such as the reviewer in the `implementation-review`
skill, gets "change nothing" as its constraint.

## Subagents in one session

1. Group the work into domains. A domain is one test file, one
   subsystem, one bug, or one research question.
2. Write one prompt for each domain.
3. Start every subagent in the same response. Several dispatch calls in
   one response run in parallel. One call per response runs them one
   after the other.
4. Wait for every subagent. Do not integrate partial results.
5. Read each report and save it under `.context/<plan-name>/`. Check
   whether two agents changed the same code. Run the checks from the
   `finish-work` skill on the combined result. Only the complete gate
   proves the combined work. Spot check the changes, because agents make
   systematic errors, for example a longer timeout that hides a race.
6. Commit with the `git-commit` skill. In the final report, say what
   each agent did, which findings you re-checked in the code, and which
   rest on the agent's evidence.

Subagents share your working tree unless the tool gives each its own
worktree. Two subagents that edit the same file overwrite each other, so
keep the scopes disjoint. In the shared tree only you commit. In its own
worktree a subagent commits on its branch with the `git-commit` skill
and does not push. Commit your own changes before you start a worktree
subagent, because a worktree holds only committed content. You then
integrate the branch with the `git-merge` skill.

## Workspaces across machines

The orchestrator splits a plan into work items and gives each item a
workspace. [references/workspaces.md](references/workspaces.md) gives
the commands. One real example: milestones 6a, 7, and 7a of a plan ran
in parallel Codex and Opus sessions. The orchestrator verified them with
one combined gate.

- The primary branch is the branch of the plan. Every workspace branch
  starts from it and merges from it, never from `main`. Only the primary
  branch merges `main`. Its pull request into `main` is the completion
  boundary from the `plans` skill.
- A work item is a milestone, or a group of TODOs in one milestone that
  touches its own files. Keep the milestone order of the plan: docs,
  then mockups, then backend, then UI. Fan out inside one level. Merge
  each branch as it finishes. Do not let branches pile up.
- The orchestrator plans, writes the prompts, delegates, and checks. It
  does not implement. A correction of a few lines found while you check
  is fine. Anything larger goes back to the delegate.
- Name the workspace `<plan-name>: <item>` and the branch
  `<plan-name>/<item>`. Add `Branch:` and the name to the TODO lines
  that the workspace owns.
- Keep a ledger under `.context/<plan-name>/workspaces.md`. It lists
  the item, the workspace id, the session id, the model, the branch, the
  pull request, the review round, and the state. Keep the prompts and
  the reports there too, never in the plan.
- The workspace agent commits with the `git-commit` skill, pushes its
  branch, and opens a pull request into the primary branch. It never
  merges. When its push fails for a missing credential, it reports the
  commit and stops.

### Models

| Work | Model | Effort |
| --- | --- | --- |
| The orchestrator and its reviewers | Fable 5.1 | max |
| Screens, components, mockups, and user-facing copy | Opus 5.5 | max |
| Everything else: backend, scripts, data, docs, research | Astra 6 | max |

Ranking, highest first: Fable 5.1, then Opus 5.5 and Astra 6 as peers,
then Sol 6.1. A block is a refusal, or a rejection that stays after one
retry: a usage limit, an input limit, a missing or revoked credential, or
a rejected model id. When a model blocks a request, send the same request
to its peer. When the peer blocks it too, send it one rank down. When
every model blocks it, stop and ask the user, with the refusal text
verbatim. When a delegate's model blocks in the middle of an item, give
the item to the peer in the same workspace, with the prompt and the diff
so far. Do not rewrite the request to hide what it does, and do not skip
the step.

| The record says | The answer |
| --- | --- |
| "Codex rejected the generated review prompt ... so no review findings were emitted." | Send the same review to the peer model. A missing review is not a result. |
| "retry this task when reviewer capacity resets." | The peer model reviews now. Record the retry time for the blocked model only. |
| "the cloud Codex CLI is unauthenticated (HTTP 401), so no review findings were produced." | A Claude reviewer with the same prompt reviews now. The review is the step. The tool is not. |

### Check, merge, and continue

1. When a workspace reports, run the `implementation-review` skill on
   its branch against the primary branch, in a fresh read-only agent. A
   large diff can split by area, one reviewer per area, with the same
   routing as the table above. Then read the diff yourself and re-run
   the checks. Confirm every ticked TODO and the push, and run the
   deletion audit from the `git-commit` skill. Never accept the report
   alone.
2. Send the findings back to the same workspace session as one fix
   request. Give the numbers, the option to apply for each, and "do not
   start the next item". The review-fix rule allows two fix rounds. Then
   you decide, or you ask the user. List every open finding under the
   plan's review TODO, as the `plans` skill says.
3. Merge the branch into the primary branch with the `git-merge` skill.
   Run the complete gate from `AGENTS.md` on the merged tree, then push.
   Each workspace ran only its own checks. The combined gate proves the
   milestone. Then archive the workspace.

   | The record says | The answer |
   | --- | --- |
   | "`cargo xtask check` passed in all ten phases on the tree before the last two merges. [...] The commits after that run change only Markdown." | The gate proves the tree that it ran on. Run it on the merged tree, or name the CI run that did. |

4. Merge `main` into the primary branch before each delegation batch,
   before each branch merge, and before the final pull request. A
   workspace never merges `main`.
5. A High finding blocks the work that depends on the affected code or
   contract. A Medium finding blocks only that dependent work. A Low
   finding never blocks. Every open finding closes before the final pull
   request merges, unless the user moves it to the post-merge follow-up
   section. Fix open findings in their own workspaces.
6. Ask the user only for blocking decisions:
   - a deletion against `origin/main`,
   - a requirement change in a protocol doc,
   - an irreversible or outward-facing action,
   - a High finding with `Auto-fix: no`,
   - a choice where any assumption wastes the work.
   For the rest, apply the recommended option. Report it in the next
   batch, in the layout of the `decisions-and-findings` skill.

## Checklist

- [ ] Every parallel task passed the independence test.
- [ ] Every prompt has Scope, Goal, Context, Steps, Constraints, and
      Output.
- [ ] Every workspace branch starts from and merges from the primary
      branch.
- [ ] A blocked request went to the peer model, then one rank down.
- [ ] The combined gate ran on the primary branch after each merge.
- [ ] The ledger and the reports are under `.context/`, not in the plan.
- [ ] Open findings block only dependent work and close before the pull
      request merges.

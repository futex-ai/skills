---
name: parallel-agents
description: How to split work across subagents that run at the same time, and how to write the prompt for any subagent. Use when you have two or more independent tasks, such as failing tests in separate files, bugs in separate subsystems, or separate research questions, before you start a subagent, and when you decide between one agent and several. Covers the independence test, one subagent per domain, the prompt with scope, goal, context, constraints, and output, dispatch in one response, the shared working tree, the summary that each subagent returns, and the integration checks.
---

# Parallel agents

A subagent is an agent with a fresh context that you start for one task.
It does not see your session, your history, or the user's messages. You
give it the exact context that it needs, and it returns a summary. This
keeps the subagent focused. It also keeps your own context free for
coordination.

When two or more tasks are independent, start one subagent for each task
in the same response. The subagents then work at the same time. Work on
independent tasks one after the other wastes time.

## Independence test

Start parallel subagents only when all of these hold:

- You know what is broken in each task. Exploratory debugging is not a
  task yet.
- Each task is clear without the context of the other tasks.
- No task needs the result of another task.
- The tasks change different files. They use different resources, such as
  ports, databases, and fixtures.
- No task needs a view of the whole system.

When one condition fails, do not split the work. Investigate the tasks
together, or run the subagents one after the other. Related failures often
share one root cause. Fix that cause first, then split what remains.

## Procedure

1. Group the work into domains. A domain is one test file, one subsystem,
   one bug, or one research question.
2. Write one prompt for each domain with the fields below.
3. Start every subagent in the same response. Several dispatch calls in
   one response run in parallel. One call per response runs them one after
   the other.
4. Wait for every subagent to return. Do not integrate partial results.
5. Integrate the results with the steps below.

## The prompt

[templates/subagent-prompt.md](templates/subagent-prompt.md) is the
template. Each prompt has these fields:

- **Scope:** the one domain. Name the files, the tests, or the question.
- **Goal:** the result that counts as done, for example "these three tests
  pass".
- **Context:** everything that the subagent needs, pasted in. Give the
  error messages, the test names, the file paths, and the commands from
  the repository's `AGENTS.md`. Name the skills to read, for example
  `deterministic-tests` for a flaky test. The subagent has no other
  context.
- **Constraints:** the files that it may change. Say what it must not do.
  Examples: change files outside the scope, commit, increase a timeout,
  delete a test, or add a retry.
- **Output:** the summary to return. Ask for the root cause, the files
  changed, the checks that ran with their results, and the open questions.

The same fields apply to one subagent. A read-only subagent, such as the
reviewer in the `implementation-review` skill, gets "change nothing" as its
constraint.

## Common mistakes

- Too broad: "fix all the tests". The subagent loses focus. Give it one
  file.
- No context: "fix the race condition". The subagent does not know where.
  Paste the errors and the test names.
- No constraints: the subagent refactors everything, or it commits. Name
  the files that it may change.
- No output contract: "fix it". You do not know what changed. Ask for the
  summary.
- One dispatch call per response. The subagents then run one after the
  other.

## Shared working tree

Subagents share one working tree unless the tool gives each subagent its
own worktree. Two subagents that edit the same file overwrite each other.
Keep the scopes disjoint. When two tasks need the same file, give both
tasks to one subagent, or run them one after the other.

In a shared working tree, only you commit. A subagent that commits hides
its change from your conflict check. In its own worktree, a subagent
commits on its branch. You then integrate the branch with the `git-merge`
skill.

## After the subagents return

1. Read each summary. Note the root cause and the files changed.
2. Check for conflicts. Did two subagents change the same code? Read the
   diff of each changed file.
3. Run the checks from the `finish-work` skill on the combined result. Each
   subagent ran only its own targeted tests. The complete gate proves the
   combined work.
4. Spot check the changes. Subagents make systematic errors, for example a
   longer timeout that hides a race.
5. Commit with the `git-commit` skill.
6. In the final report, say what each subagent did and which checks ran.
   Use the layout in the `decisions-and-findings` skill.

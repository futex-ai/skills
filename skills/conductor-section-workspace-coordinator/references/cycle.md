# The cycle in detail

This reference gives the action for each stage on the board. The stages
are `new`, `planning`, `implementing`, `review`, `merge`, `done`, and
`blocked`. A workspace moves forward one stage at a time. The board
records the stage, the active session, the next action, and the date of
the last change.

## Read a report

- `scripts/last-report.sh`, with the session id, prints the last message
  that the child's agent wrote. A complete task ends with the
  final-report layout: **Changed**, **Fixed**, **Decisions**, **Checks**,
  **Open**.
- When the session is `working`, do not read it and do not send to it.
  Wait for `idle`.
- When the last message is not a final report, for example a question or
  an error, answer the question or send the status request.
- Keep what the next cycle needs in the board line: the branch, the pull
  request number, and the open items. Do not copy reports into the state
  file.

## Stages

| Stage | The child is | When its session is idle |
| --- | --- | --- |
| `new` | just added to the section | Read the last report. A workspace that you created has its plan request already, so set `planning`. For a workspace that the user added, set the stage that the report shows: a pushed plan is `planning`, a pull request is `review`. When the report shows neither, send the status request. When the workspace has no task, its name is the goal: send the plan request. |
| `planning` | writing the plan | The report names a branch with a pushed plan and no pull request, as the `plans` skill says. Review the plan against the checks below. Send the amendments message and keep the stage, or approve: start the implementation session with the `implementation` role, or the `complex` role, and the implement message, and set `implementing`. |
| `implementing` | implementing the plan | Read the report. Answer the decisions and the review items. A report with an open pull request, every milestone ticked, and no open item goes to `review`. A blocked report goes to `blocked` with the blocker on the board. When the report says that the branch conflicts with `main`, send the merge-main message. |
| `review` | done, pull request open | Check the merge conditions in `SKILL.md`. When they hold, set `merge`. When a condition fails because of the child, send the message that names the gap and set `implementing`. When it fails because of an escalation, set `blocked`. |
| `merge` | waiting for the merge | Merge as `SKILL.md` says. Send the after-merge message. When the plan status pull request is merged, archive the workspace and set `done`. |
| `done` | archived | Nothing. Keep the line for one week, then drop it. |
| `blocked` | waiting for the user or another section | Check each cycle whether the blocker is gone: an answered escalation, a merged pull request of another section, or a user message. Then set the stage that the work needs. |

## Plan checks

- The scope matches the goal and nothing more.
- Each milestone leaves the product working, and its pull request can
  merge within a day.
- The first milestone updates the docs, as the `plans` skill says.
- The plan names the files or areas of each milestone.
- No milestone touches the areas of other active work. See the
  scheduling reference.
- Milestones that depend on each other become a stack, one pull request
  per milestone with `gh stack`. Independent milestones can become
  separate workspaces when their areas do not overlap.
- For a plan with three or more milestones, or a complex area, delegate a
  plan review with the `default` role before you approve.

## Messages

- Name the stage that you expect next and the report that you want.
- Never send code. Describe the change in words. A child that needs a
  design decision gets the decision, not the implementation.
- When the child asks a question that the goals answer, answer it. When
  the goals do not answer it and the choice is not reserved for the user,
  decide, and record the decision in the log. Otherwise escalate.

## Stacks

Merge a stack from the bottom, one pull request at a time, under the
merge conditions. After each merge, the after-merge message asks the
child to run `gh stack sync` and to report the next pull request.

## Restart

When this session grows too long or stops, start a new session in this
workspace, invoke the skill, archive the old session, and rename the new
one `coordinator`. The state file holds everything that a cycle needs.

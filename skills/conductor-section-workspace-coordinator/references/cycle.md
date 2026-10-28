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
- When the last message is a question, answer it. When it is an error,
  or not a final report, send the status request.
- Keep what the next cycle needs in the board line: the branch, the pull
  request number, and the open items. Do not copy reports into the state
  file.

## Stages

| Stage | The child is | When its session is idle |
| --- | --- | --- |
| `new` | just added to the section | Read the last report. A workspace that you created has its plan request already, so set `planning`. A workspace that the user added gets the stage that its report shows. A pushed plan is `planning`. A pull request is `review`. When the report shows neither, send the status request. When the workspace has no task, its name is the goal: send the plan request. |
| `planning` | writing the plan | The report names a branch with a pushed plan and no pull request, as the `plans` skill says. Review the plan against the checks below. To amend the plan, send the amendments message and keep the stage. To approve it, send the implement message to the same session and set `implementing`. The orchestrator then delegates the milestones inside its workspace. |
| `implementing` | implementing the plan | Read the report. Answer the decisions and the review items. A report with an open pull request, every milestone ticked, and no open item goes to `review`. A blocked report goes to `blocked` with the blocker on the board. When the report says that the branch conflicts with `main`, send the merge-main message. |
| `review` | done, pull request open | Check the merge conditions in `SKILL.md`. When they hold, set `merge`. When a condition fails because of the child, send the message that names the gap and set `implementing`. When it fails because of an escalation, set `blocked`. |
| `merge` | waiting for the merge | Merge as `SKILL.md` says. Send the after-merge message. When the plan status pull request is merged, set `done`. |
| `done` | finished | Archive the workspace, as the section below says. Keep the line for one week, then drop it. |
| `blocked` | waiting for the user or another section | In each cycle, check whether the blocker is gone. Examples: an answered escalation, a merged pull request of another section, or a user message. Then set the stage that the work needs. |

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
- Before you approve a large plan, delegate a plan review with the
  `first-pass review agent` action. A large plan has three or more
  milestones, or a complex area.

## Messages

- Name the stage that you expect next and the report that you want.
- Never send code. Describe the change in words. A child that needs a
  design decision gets the decision, not the implementation.
- When the child asks a question that the goals answer, answer it. When
  the goals do not answer it and the choice is not reserved, decide.
  Record the decision in the log. Escalate a reserved choice.

## Archive

Archive a workspace that the section no longer needs, with
`conductor workspace archive <id>`. An archived workspace stays
restorable. A workspace is finished when:

- its pull request merged, and its plan status pull request merged,
- its work was dropped, or another workspace took it over,
- the user says that it is no longer needed.

After you read the report of a goal review, a plan review, or an
investigation, archive its session. The command is
`conductor session archive <id>`. Do not archive a workspace at stage
`blocked`. Record each archive in the log.

## Stacks

Merge a stack from the bottom, one pull request at a time, under the
merge conditions. After each merge, the after-merge message asks the
child to run `gh stack sync` and to report the next pull request.

## Restart

When this session grows too long or stops, start a new session in this
workspace and invoke the skill. Archive the old session. Rename the new
one `coordinator`. The state file holds everything that a cycle needs.

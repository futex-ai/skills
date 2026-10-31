# The cycle in detail

This reference gives the action for each stage on the board. The stages
are `new`, `planning`, `implementing`, `review`, `merge`, `done`, and
`blocked`. A workspace moves forward one stage at a time. The board
records the stage, the orchestrator session, the next action, and the
date of the last change.

## Read a report

- `scripts/last-report.sh`, with the orchestrator's session id, prints
  how the orchestrator's last turn ended. A complete task ends with the
  final-report layout: **Changed**, **Fixed**, **Deferred**,
  **Decisions**, **Checks**, **Open**. A turn that failed prints its
  error with the prefix `error: `.
- When the session is `working`, do not read it and do not send to it.
  Wait for `idle`.
- When the last message is a question, apply the decisions section of
  `SKILL.md`. When it is not a final report, send the status request.
- When it is an error, send the status request once. That is the one
  retry of the `delegating` skill. When the next turn ends in an error
  too, the action is blocked. Escalate it with the error text, and set
  `blocked`.
- Keep what the next cycle needs in the board line: the branch, the pull
  request number, and the open items. Do not copy reports into the state
  file.

## Stages

| Stage | The child is | When its orchestrator is idle |
| --- | --- | --- |
| `new` | just added to the section | A workspace that you created has its orchestrator and its plan request, so set `planning`. A workspace that the user added gets an orchestrator and then a stage, as the section below says. |
| `planning` | writing the plan | A brainstorm report has no plan yet. Answer its items under `SKILL.md`, and keep the stage. A plan report names a branch with a pushed plan and no pull request, as the `plans` skill says. Review the plan against the checks below. To amend the plan, send the amendments message and keep the stage. To approve it, send the implement message to the orchestrator and set `implementing`. |
| `implementing` | implementing the plan | Read the report. Handle the items of its **Open** list under `SKILL.md`. A report with an open pull request and every milestone ticked can go to `review`. Move it when no item blocks that pull request. A blocked report goes to `blocked` with the blocker on the board. When the report says that the branch conflicts with `main`, send the merge-main message. |
| `review` | done, pull request open | Check the merge conditions in `SKILL.md`. When they hold, set `merge`. When a condition fails because of the child, send the message that names the gap and set `implementing`. When it fails because of an escalation, set `blocked`. |
| `merge` | waiting for the merge | Merge as `SKILL.md` says. In the middle of a stack, send the stack message and set `review` for the next pull request. After the last pull request, set `done`. |
| `done` | finished | Archive the workspace, as the section below says. Keep the line for one week, then drop it. |
| `blocked` | waiting for the user or another section | In each cycle, check whether the blocker is gone. Examples: an answered escalation, a merged pull request of another section, or a user message. Then set the stage that the work needs. |

## Give a workspace an orchestrator

Every child workspace has one session named `orchestrator` with the
`default orchestrator` action. A workspace that you create gets it at
creation. A workspace that the user added gets it in its `new` stage:

1. Wait until the newest session of the workspace is idle. The scan
   gives its id, name, model, and effort. Read its last report.
2. When that session runs the model and the effort of the
   `default orchestrator` action, adopt it. Rename it with
   `conductor session rename <id> --name orchestrator`. Send it the
   status request.
3. Otherwise, start a new session with the `default orchestrator`
   action. Run `conductor session create --workspace <id> --name
   orchestrator --agent <agent> --model <model> --effort <effort>
   --message-file <path>`. Take the three values from that action in the
   `models` skill. The message file holds the status request.
   Put the last report of the newest session into that message.
4. Leave the other sessions of the workspace as they are. Record the
   orchestrator's session id on the board.

A workspace without a session gets a new orchestrator session too. Its
first message is the plan request, with the workspace name as the goal.

Then set the stage that the orchestrator's report shows. A pushed plan
is `planning`. A pull request is `review`. With neither, send the plan
request, and set `planning`. Its goal is the task in the report, or else
the workspace name.

## Plan checks

- The scope matches the goal and nothing more.
- Each milestone leaves the product working, and its work can merge
  within a day.
- The milestones follow the order of the `plans` skill. The mockup
  milestone comes first when the plan has mockup work. The documentation
  milestone comes next.
- Each milestone has a `Depends on:` line, as the `plans` skill says.
- The plan names the files or areas of each milestone.
- No milestone touches the areas of other active work. See the
  scheduling reference.
- Milestones that start together run in parallel workspaces of the
  orchestrator, as the `delegating` skill says. Milestones that depend on
  each other can merge as a stack, one pull request per milestone with
  `gh stack`. Then each merges within a day.
- Before you approve a large plan, delegate a plan review with the
  `first-pass review agent` action. A large plan has three or more
  milestones, or a complex area.

## Messages

- Name the stage that you expect next and the report that you want.
- Never send code. Describe the change in words. A child that needs a
  design decision gets the decision, not the implementation.
- Handle each item under "Decisions and review items" in `SKILL.md`.
  Record each answer in the log. Escalate each choice that needs the user.

## Archive

Archive a workspace that the section no longer needs, with
`conductor workspace archive <id>`. An archived workspace stays
restorable. A workspace is finished when:

- every pull request of its change merged,
- its work was dropped, or another workspace took it over,
- the user says that it is no longer needed.

After you read the report of a goal review, a plan review, or an
investigation, archive its session. The command is
`conductor session archive <id>`. Do not archive a workspace at stage
`blocked`. Record each archive in the log.

## Stacks

Merge a stack from the bottom, one pull request at a time, under the
merge conditions. After each merge in the middle of the stack, send the
stack message. It asks the child to run `gh stack sync` and to report
the next pull request. Only the last pull request of the stack deletes
the plan, as the `plans` skill says.

## Restart

When this session grows too long or stops, start a new session in this
workspace and invoke the skill. Archive the old session. Rename the new
one `coordinator`. The state file holds everything that a cycle needs.

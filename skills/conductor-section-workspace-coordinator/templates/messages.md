# Messages to children and to other coordinators

Fill each `<slot>`. Keep the sentences short. Send a message only to an
idle session, and put everything for that session into it. The children
follow the shared skills, so name the skill that governs each step.

A message that starts a workspace or a session is a delegation prompt.
It has the six fields of the `delegating` skill: Scope, Goal, Context,
Steps, Constraints, and Output. The other messages continue a
delegation, so they need no fields.

## Plan request

The first message of a new workspace, to its orchestrator.

    Scope: the change "<change>" in the Conductor section "<section>".

    Goal: <the change, the metric it serves, and the result, in two or
    three sentences>. Done means a pushed plan that the coordinator can
    approve.

    Context:
    - You are the orchestrator of this workspace. You manage the work
      here. The section coordinator sends its messages to you and reads
      your reports. It answers your items and merges your pull request.
    - <Approach: the approach that a goal review or a decision chose,
      with its source. Leave this line out when the approach is open.>
    - <The areas, the files, and the earlier work to read first.>
    - The repository rules in `AGENTS.md` apply.

    Steps:
    1. When no line above chooses the approach, brainstorm first with
       the `brainstorming` skill. Report its items, and wait for the
       answers.
    2. Write the plan with the `plans` skill. Keep each milestone small
       enough that its work merges within a day. <When the milestones
       depend on each other: plan one pull request per milestone as a
       stack with `gh stack`.>
    3. Commit the plan, and push the branch.

    Constraints:
    - Write no code before the coordinator approves the plan.
    - Open no pull request. Never merge yourself.
    - <Files or areas to avoid, and why.>

    Output: the final report of the `decisions-and-findings` skill. Give
    the branch, the plan file, and the milestones with their `Depends on:`
    lines. Give the files or areas that each milestone touches. List each
    item that needs an answer, with lettered options.

## Status request

For the orchestrator of a workspace that the user added, or for an
orchestrator whose last message is not a final report.

    Scope: this workspace and its branch.

    Goal: a report of the state of the work.

    Context:
    - The coordinator of the section "<section>" now coordinates this
      workspace. You are its orchestrator. You manage the work here. The
      coordinator sends its messages to you and reads your reports.
    - <For a new orchestrator session: The session <id> worked here
      before you. Its last report follows: <report>.>

    Steps: read the branch, the plan, and the pull request.

    Constraints: change nothing.

    Output: the final report of the `decisions-and-findings` skill. Give
    the branch, the plan file, and the pull request. Say what is done and
    what is open. List each item that needs an answer, with lettered
    options. Name every blocker.

## Plan amendments

    Amend the plan: <numbered list of changes, one sentence each, with
    the reason>. Then commit, push, and report again in the same layout.

## Implement

To the workspace's orchestrator session, after the plan is approved.

    The plan on branch `<branch>` is approved. Implement all plan
    milestones by delegation, as the `plans` skill says. The docs work
    goes to the `docs implementor`, the UI work to the `ui implementor`,
    and the other work to the `non-ui implementor`. The `models` skill
    names the model of each action, and the `delegating` skill its
    route. Check the delegated work and request changes as needed. Run
    the checks and the review that the `finish-work` skill requires. Open
    the pull request when every milestone TODO is ticked.
    <When a stack was agreed: one pull request per milestone with
    `gh stack`.> When the branch is behind `origin/main`, merge it first
    with the `git-merge` skill. Answers: <number: letter and one sentence,
    for each item of the plan report>. Report when the pull request opens,
    or when an item needs an answer, in the final-report layout. Never
    merge yourself.

## Answers to decisions and review items

    Answers to your report of <date>:
    1. <letter>. <one sentence>.
    2. <letter>. <one sentence>.

    Item <n> waits for the user. Apply no option for that item.
    Schedule: <the current pull request is blocked, or the dependent work
    moves to a follow-up pull request>. Reason: <why the current pull request
    needs the answer, or meets its approved requirements without it>.

    <For deferred work: Keep item <n> open in the report. Record it as a
    follow-up item, as the `plans` skill says, and give its path.>
    Continue with the independent work. Apply the answered options.

    Run the checks. Commit the changes. Push the branch.
    Re-review once. Report again in the final-report layout.

## Investigation

A new session in the child's workspace, with the `second-pass review
agent` action.

    Scope: one item of the last report in this workspace: <title>.

    Goal: the evidence that settles <the question that the answer must
    settle>.

    Context: <the item, with its options and its recommendation, pasted
    in full>.

    Steps: read the code that the item names. Write the options with the
    options rule of the `decisions-and-findings` skill: the root
    question, at least three distinct approaches, and **Left out**.

    Constraints: read only. Change no file.

    Output: the evidence, with file paths and lines. Recommend one of the
    lettered options, or a new option with its effort.

## Plan review

A new session in the child's workspace, with the `first-pass review
agent` action.

    Scope: the plan `<plan file>` on this branch.

    Goal: the amendments that the plan needs before its approval.

    Context: the goal of the change: <goal>. <The active work in nearby
    areas, from the board.>

    Steps: check that the scope matches the goal. Check that each
    milestone leaves the product working, and that its work can merge
    within a day. Check the milestone order and the `Depends on:` lines,
    as the `plans` skill gives them. Name the files or areas that each
    milestone touches.

    Constraints: read only. Change no file.

    Output: the amendments that you recommend, numbered, each with its
    reason.

## Merge main

    `main` moved under your branch: <the merged pull request and the
    files>. Merge `origin/main` into the branch with the `git-merge`
    skill, run the checks, push, and report.

## Stack

After a pull request in the middle of a stack.

    Pull request #<n> merged as <commit>. Run `gh stack sync`, and report
    the next pull request of the stack. Keep the plan: the last pull
    request of the stack deletes it. Do no other work.

## Goal review

The first message of a session named `review: <goal>` in the
coordinator's workspace, with the `brainstorming` action.

    Scope: the goal of the section "<section>": <goal, with the metric,
    its current value, and the target>.

    Goal: up to five candidate changes that move the metric toward the
    target.

    Context: <the areas of the section, the active work, and the earlier
    goal reviews>.

    Steps:
    1. Follow steps 1 to 4 of the `brainstorming` skill. Read the open
       follow-up items first, with the script of the `plans` skill.
    2. Measure the metric now, and record how.
    3. For each candidate, give the expected effect on the metric and
       the effort, as the `decisions-and-findings` skill grades it. Give
       the files or areas, and the risks. Order the candidates by effect
       per effort.

    Constraints: change no tracked file.

    Output: the final-report layout. Name each candidate that is an open
    follow-up item, with its path.

## Coordination with another section

To the session named `coordinator` of a workspace named
`coordinator: <other section>`.

    From the coordinator of "<section>". I plan to change <areas or
    files> for <goal>, starting <when>. Your section has <the workspace
    or pull request> in the same area. Proposed order: <who goes first,
    and what the other avoids>. Reply with your agreement or another
    order. Without a reply by my next cycle, I start and avoid the shared
    files.

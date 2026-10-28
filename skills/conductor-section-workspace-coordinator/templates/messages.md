# Messages to children and to other coordinators

Fill each `<slot>`. Keep the sentences short. Send a message only to an
idle session, and put everything for that session into it. The children
follow the shared skills, so name the skill that governs each step.

## Plan request

The first message of a new workspace, to its orchestrator.

    You are the orchestrator of this workspace, in the Conductor section
    "<section>". You manage the work here. The section coordinator sends
    its messages to you and reads your reports. It answers your decisions
    and merges your pull request. Never merge yourself.

    Goal: <the change, the metric it serves, and the result, in two or
    three sentences>.
    Constraints: <files or areas to avoid, and why. The repository rules
    in AGENTS.md apply.>

    Write a plan with the `plans` skill, and nothing more. Keep each
    milestone small enough that its pull request merges within a day.
    <When the milestones depend on each other: plan one pull request per
    milestone as a stack with `gh stack`.> Commit the plan, push the
    branch, and open no pull request. End with the final report of the
    `decisions-and-findings` skill. Give the branch, the plan file, and
    the milestones. Give the files or areas that each milestone touches.
    Number every decision that you need, with lettered options.

## Status request

For the orchestrator of a workspace that the user added, or for an
orchestrator whose last message is not a final report.

    The coordinator of the section "<section>" now coordinates this
    workspace. You are its orchestrator. You manage the work here. The
    coordinator sends its messages to you and reads your reports.
    <For a new orchestrator session: The session <id> worked here before
    you. Its last report follows: <report>.> Report in the final-report
    layout of the `decisions-and-findings` skill. Give the branch, the
    plan file, and the pull request. Say what is done and what is open.
    Number every decision that you need, with lettered options. Name
    every blocker. Change nothing.

## Plan amendments

    Amend the plan: <numbered list of changes, one sentence each, with
    the reason>. Then commit, push, and report again in the same layout.

## Implement

To the workspace's orchestrator session, after the plan is approved.

    The plan on branch `<branch>` is approved. Implement all plan
    milestones by delegation, as the `plans` skill says. The docs work
    goes to the `docs implementor`, the UI work to the `ui implementor`,
    and the other work to the `non-ui implementor`. The `models` skill
    names the model of each action. Check the delegated work and request
    changes as needed. Run the checks and the review that the
    `finish-work` skill requires. Open the pull request when every
    milestone TODO is ticked.
    <When a stack was agreed: one pull request per milestone with
    `gh stack`.> When the branch is behind `origin/main`, merge it first
    with the `git-merge` skill. Decisions: <number: letter and one
    sentence, for each decision of the plan report>. Report when the pull
    request opens, or when you need a decision, in the final-report
    layout. Never merge yourself.

## Answers to decisions and review items

    Answers to your report of <date>:
    1. <letter>. <one sentence>.
    2. <letter>. <one sentence>.
    Item <n> waits for the user. Continue with the other items. Apply the
    answers, run the checks, commit, push, re-review once, and report
    again in the final-report layout.

## Investigation

A new session in the child's workspace, with the `second-pass review
agent` action.

    Investigate item <n> of the last report in this workspace: <title>.
    <The question that the answer must settle.> Read only. Change no
    file. Report the evidence, with file paths and lines. Recommend one
    of the lettered options, or a new option with its effort.

## Plan review

A new session in the child's workspace, with the `first-pass review
agent` action.

    Review the plan `<plan file>` on this branch. Read only. Check that
    the scope matches this goal: <goal>. Check that each milestone leaves
    the product working. Check that the first milestone updates the docs,
    and that each milestone can merge within a day. Name the files or
    areas that each milestone touches. Report the amendments that you
    recommend, numbered, with the reason.

## Merge main

    `main` moved under your branch: <the merged pull request and the
    files>. Merge `origin/main` into the branch with the `git-merge`
    skill, run the checks, push, and report.

## After merge

    Pull request #<n> merged as <commit>. Update the plan status as the
    `plans` skill says, on a new branch, and open its pull request. Report
    its number. <For a stack: run `gh stack sync` and report the next
    pull request.> Do no other work.

## Goal review

The first message of a session named `review: <goal>` in the
coordinator's workspace, with the `brainstorming` action.

    Goal of the section "<section>": <goal, with the metric, its current
    value, and the target>. Measure the metric now and record how. Find
    the opportunities to move it toward the target. Propose up to five
    candidate changes. For each give the expected effect on the metric
    and the effort, as the `decisions-and-findings` skill grades it. Give
    the files or areas, and the risks. Order them by effect per effort.
    Change no tracked file. Report in the final-report layout.

## Coordination with another section

To the session named `coordinator` of a workspace named
`coordinator: <other section>`.

    From the coordinator of "<section>". I plan to change <areas or
    files> for <goal>, starting <when>. Your section has <the workspace
    or pull request> in the same area. Proposed order: <who goes first,
    and what the other avoids>. Reply with your agreement or another
    order. Without a reply by my next cycle, I start and avoid the shared
    files.

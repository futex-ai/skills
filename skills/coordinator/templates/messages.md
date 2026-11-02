# Messages to children

Fill each `<slot>`, and delete the lines that do not apply. Write each
message to a file under `.context/coordinator/messages/`, and send it to
the orchestrator of the child, as the cycle reference of the skill says.
Record the id of each message on the board.

A message that starts a workspace or a session has the six fields of the
`delegating` skill: Scope, Goal, Context, Steps, Constraints, and Output.
The child prompt, the new orchestrator prompt, and the handover message
start one. The other messages continue a request, so they need no fields.

## Child prompt

The first message of a new child.

    Scope: the change "<change>" in `<owner/repo>`. <The files or the
    areas, when the request of the user names them.>

    Goal: a pull request into `main` that <the result that the user asked
    for>. Its checks pass and its post-push review is done. The pull
    request stays open. The coordinator merges it.

    Context:
    - The user asked for this change: "<the words of the user>".
    - You are the orchestrator of this workspace. A coordinator session
      manages this workspace for the user. It sends you its messages,
      reads your reports, relays your items to the user, and merges your
      pull request.
    - Read `AGENTS.md` first. Follow the normal flow of the shared
      skills: `brainstorming`, `plans`, `delegating`, `finish-work`, and
      `implementation-review`.
    - <Approach: the approach that the user chose, and the date.>
    - <Agent and model: the user asked that this workspace runs on
      <agent> `<model>` at `<effort>`.>
    - <The files, the docs, or the earlier work to read first.>

    Steps:
    1. When no line above chooses the approach, brainstorm with the
       `brainstorming` skill. Report the root questions, and wait for the
       answers.
    2. Write the plan with the `plans` skill. Commit it, push the branch,
       and report. Wait for the approval of the plan.
    3. Implement the plan by delegation, as the `plans` skill says.
    4. Run the checks and the review that the `finish-work` skill
       requires. Commit and push.
    5. Open a pull request into `main` with `gh pr create --base main`.
    6. Wait for the CI checks of the pull request, and report their
       result.

    Constraints:
    - Do not merge your pull request. The coordinator merges it.
    - Ask every question in your reply, in the layout of the
      `decisions-and-findings` skill. Keep the numbers and the letters of
      your items in later reports.
    - Change only <the scope>. When the work needs a change outside the
      scope, stop and report it.

    Output, in your final message, in the final-report layout of the
    `decisions-and-findings` skill:
    - The pull request URL and the commit.
    - What changed, in two to five sentences.
    - The checks that ran, and the CI result of each check of the pull
      request.
    - Whether the implementation is complete under the `finish-work`
      skill, and whether its review is done.
    - The items that need the user, each with its number and its lettered
      options.
    - The merge method that `AGENTS.md` names, or "none".
    - The follow-up items that the change adds, and the problems outside
      the scope.

## New orchestrator prompt

For a child whose orchestrator is lost, and for a workspace without an
open session. Use the child prompt, or the handover message for a
workspace that the user handed over. Add these lines to its Context:

    - The session <id> was the orchestrator of this workspace. It is
      lost: "<the error>". Its last report follows, or "none":
      <the report>.
    - Read the branch, the plan, and the pull request first. Continue from
      the state that they show. Do not start the work again.

## Handover message

The first message to the orchestrator of a workspace that the user hands
over.

    Scope: this workspace, its branch, its plan, and its pull request.

    Goal: a report of the state of the work, so that the coordinator can
    manage this workspace from now on.

    Context:
    - The user handed this workspace to a coordinator session on <date>.
      The coordinator sends you its messages, reads your reports, relays
      your items to the user, and merges your pull request into `main`.
    - You stay the orchestrator of this workspace. Follow the normal flow
      of the shared skills.

    Steps: read the branch, the plan, and the pull request. Then report.

    Constraints:
    - Change nothing for this message.
    - Do not merge your pull request. The coordinator merges it.
    - Ask every question in your reply, in the layout of the
      `decisions-and-findings` skill.

    Output: the final-report layout of the `decisions-and-findings`
    skill. Give the branch, the plan file, the pull request, and the merge
    method that `AGENTS.md` names, or "none". Say what is done and what is
    open. List each item that needs the user, with its number and its
    lettered options. Name every blocker.

## Status request

For a request that ended without a final report or a question, and for
`waiting:` tasks that stayed from the last cycle.

    Status request from the coordinator. When the work of your last
    request is not complete, finish it first. Then report in the
    final-report layout of the `decisions-and-findings` skill. Give the
    branch, the plan file, and the pull request. Say what is done and what
    is open. List each item that needs the user, in your own numbers. Name
    every blocker.

## Retry message

For a request that ended on an error. Cancel a stalled session first.

    Your last request stopped on this error: "<cause>". Continue its work
    from where it stopped. Do not start it again. Then report in the
    final-report layout of the `decisions-and-findings` skill.

## Answers message

The answers of the user to the items of a child, in the numbers of the
child.

    Answers of the user to your items, on <date>, in your numbers:
    - Item <number of the child>: <letter>. <"The words of the user",
      when the user added any.>
    - Item <number of the child>: <letter>.

    Apply each answered option. Items <numbers> still wait for the user.
    Apply no option for them. Continue the work, and report in the
    final-report layout when it is done or when an item needs the user.

## Plan approval message

After the user approves the plan of a child.

    The user approved the plan `<plan file>` on the branch `<branch>` on
    <date>. <The changes that the user asked for, in the words of the
    user.> Implement the plan by delegation, as the `plans` skill says.
    Run the checks and the review that the `finish-work` skill requires.
    Open the pull request into `main`, and wait for its CI checks. Report
    in the final-report layout. Do not merge your pull request.

## Fix request

The gaps of the merge check, one block for each gap.

    Fix request from the coordinator for <owner/repo>#<n>. Do not start
    other work.

    Gap 1: <the condition of the merge check that fails, in one sentence>.
    - Evidence: <the check, its link, and its failure text, or the line of
      your report>.
    - Apply this fix: <the exact change or step>. Change nothing else.

    When a gap has a cause outside your change, do not fix it. Show the
    cause with its evidence, for example the run of the same check on
    `main`.

    Run the checks and the review that the `finish-work` skill requires.
    Commit and push. Wait for the CI checks, and report in the
    final-report layout. Do not merge the pull request.

## Merge-main message

After a merge that changes a file of another child.

    `main` moved under your branch: <owner/repo>#<n> merged as <commit>,
    and it changed <files>. Merge `origin/main` into your branch with the
    `git-merge` skill. Run the checks, push, and report in the
    final-report layout. Do not start other work.

## Stack message

After each merge below the top of a stack.

    Pull request #<n> of your stack merged as <commit>. Run
    `gh stack sync`, and report the next pull request of the stack. Do no
    other work.

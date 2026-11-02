# Coordinator skill

Status: Active. On branch `calummoore/coordinator-skill-design`, no pull request yet. The pull request that completes the work deletes this plan, as the `plans` skill says.

The user asked on 2026-11-01 for a coordinator skill. A coordinator is
one session in its own Conductor workspace. It manages other workspaces
and never works on its own branch. It talks to the orchestrator session
of each workspace, and the user talks only to the coordinator. It keeps
its role in context once started. It reports the findings up, passes
the answers back, and merges each workspace into `main` when ready. It
works as autonomously as possible.

The change does not wake a sleeping coordinator, as item 2 says. It does
not edit or close PR #37. The facts behind the design are in
`.context/coordinator-skill/brainstorm.md`. Contract owners: the
[README](../README.md), and the skills whose rules the coordinator
follows: `delegating`, `models`, `decisions-and-findings`,
`finish-work`, and `plans`.

Terms:

- **Child:** a workspace that the coordinator manages. It holds one
  change and opens one pull request into `main`.
- **Orchestrator:** the first session of a child, on the
  `default orchestrator` action of the `models` skill.
- **Role hook:** `scripts/role-hook.sh`, which Claude Code runs on each
  prompt and at each session start to remind a marked session of its role.
- **Reader:** `skills/coordinator/scripts/last-report.sh`, which prints
  one line about the latest request of a session.

## Decisions

The user answered these items on 2026-11-01, after a brainstorm, so no
options check ran.

- **Item 1, A.** Write a new, small `coordinator` skill on this branch,
  from the request. Take the reader and its tests from PR #37, and add
  the role hook. Rejected: B, rework PR #37 on its branch. C, answer the
  six open items of PR #37, merge it, and add the role hook after. A was
  the recommendation, because it builds only what the request asks for.
- **Item 2.** "we will handle outside of the skill", so the skill holds
  no wake mechanism. Rejected: A, background waits. B, child notices. C,
  both, which was the recommendation. D, an hourly Conductor routine.
- **Item 6, A.** The coordinator answers no item. Every item whose
  **Action** is `ask the user` goes to the user. The coordinator still
  runs merges, retries, and fix requests alone. This is item 6 of the
  PR #37 workspace, with its letters and a new D. Rejected: B, the named
  classes and the reserved choices. C, only the reserved choices,
  as decision 4 A of 2026-10-28 said. D, answer the items whose only
  reason is a trade-off, which was the recommendation.

The brainstorm left out these approaches:

- A section in `delegating`, which is at its 200-line limit, and two
  coordinator skills, which split the rules of one role.
- A program that drives the workspaces: it needs a host that stays awake
  while workspaces sleep, and an agent must still read the reports.
- `/loop` or a rule in the skill to keep the role: `/loop` stops when the
  workspace sleeps, and a rule fails when the agent forgets it.
- The coordinator mode in the Claude Code binary, which has no docs, and
  a custom output style, which Conductor sets for each session.

## Design

Each design call is marked "My call", with its reason, on 2026-11-01.

### The role and its limits

- The user starts it with `/coordinator` in a workspace of its own. My
  call: the name says the role. Its description is the one in the stub
  `skills/coordinator/SKILL.md`, which names the role hook's reminder.
- It runs the `default orchestrator` action. My call: it needs the same
  judgment, and the `models` table stays as the user set it.
- It manages the children that it starts for the user and the workspaces
  that the user hands to it, in any repository, with no sections. My
  call: the request names workspaces, and the README fan-out session of
  2026-11-01 spanned 13 repositories.
- It sends every message for a child to the orchestrator, by the session
  id that it recorded at the start, or that the user named. My call: this
  settles item 5 of PR #37 without a rename or an archive of a session.
- It never edits, commits, or pushes in its own checkout. It only
  fast-forwards it, and writes only under `.context/coordinator/`.
- Its board is `.context/coordinator/state.md`. My call: a new session
  takes over from it after `/coordinator`.

### What goes to the user

Under item 6 A, these go to the user, in one numbered list per message:

- every item of a child whose **Action** is `ask the user`,
- every brainstorm root question and every plan that waits for approval,
- the coordinator's own items: a model block, a merge that a required
  check blocks, and a repository that it cannot reach.

Each item uses the `decisions-and-findings` layout. It names its child
and the child's own number, and keeps the child's letters. Each answer
goes back to its child, in the child's numbers. The coordinator never
answers an item and never applies an option.

My call: under item 6 A the user approves each plan and each split of a
child. I withdrew my brainstorm call that the coordinator approves plans.

Alone, the coordinator starts a child for each change that the user asks
for, sends status requests, retries, sends the gaps of the merge check
back, merges, asks children to merge `main`, and archives them.

### Each cycle

Every message starts a cycle: from the user, from a child, or from the
wake mechanism outside the skill. The skill does not wait for children.

1. Fetch, fast-forward to `origin/main`, read the board, and apply the
   message: new changes, answers, or a handed-over workspace.
2. Read each active child with the reader, and act by its stage, as
   `references/cycle.md` says. Merge each child that passes the check.
3. Start the new children, in parallel only when they pass the
   independence test of `delegating`. My call: such branches conflict.
4. Write the board, and report in the final-report layout.

### Starting and reading a child

- Create a child with `conductor workspace create`, the
  `default orchestrator` action, and the child prompt of
  `templates/messages.md`, in the six fields of `delegating`: follow the
  normal flow, ask in the reply, end with a final report, open the pull
  request into `main`, and never merge it. The user can name another
  agent for one task. A repository without a project gets `--repo-url`.
- The reader prints `pending:`, `waiting:`, `error:`, the last text, or
  nothing, as in PR #37. A new result, `error: stalled: <cause>`, marks a
  `working` session whose last event is an error with no event in the
  next 15 minutes. My call: this is option A of item 16 of the PR #37
  workspace, and item 6 A gives retries to the coordinator.
- A request that ends without a final report or a question gets one
  status request. A stalled child gets one cancel and one retry. A model
  block, or a retry that fails, becomes an item for the user.
- The reader prints `pending: working, last event <age> ago`, and each
  report names that age for each working child. My call, 2026-11-02:
  case R3 hung for 22 hours with no error event, which the stall misses.

### Merging

The coordinator merges a child's pull request into `main` when all of
these hold:

1. The child's final report says that the implementation is complete
   under the `finish-work` skill, and that its review is done.
2. Each required check passes, as `gh pr checks <n> --required` shows.
3. Each check that is not required passes, or fails on the latest run
   of `main` too. Otherwise the check goes back to the child once. When
   the child shows a cause outside the change, the merge becomes an item.
   My call, corrected on 2026-11-02: a failure only on the branch can be
   a regression, and the README fan-out merged two such checks unproven.
4. The pull request is not a draft, and GitHub can merge it.
5. Each item of the change is closed, or the user moved it to the
   post-merge follow-up.

It merges with the method that `AGENTS.md` names, or a squash, and
deletes the branch. It never runs an admin bypass on its own. After the
merge it archives the child, asks each child that edits the same files
to merge `main`, and names the new follow-up items, as `finish-work` says.

### The role hook

- The skill's `role.sh start` writes `coordinator` to `~/.futex/roles/<id>`,
  and `stop` removes it. `<id>` is `CONDUCTOR_SESSION_ID` when set, else
  the Claude session id, which `/clear` changes (M3 review, finding 1).
  Without a Claude session id, it says that the hook needs Claude Code.
  My call: the marker names a skill, so that another role can use it.
- `scripts/role-hook.sh` reads the hook input without jq. For a marked
  session it prints a short reminder on `UserPromptSubmit`, and on
  `SessionStart`, also after a compaction, to read the skill file now.
  Otherwise it prints nothing. It exits 0 on every input, and removes
  markers idle for 30 days.
- `install.sh --hooks` adds it to both events as a synchronous command,
  and `--uninstall` removes it. My call: `update.sh` does not change,
  because each change under `scripts/` runs on every machine. An old
  install gets the role hook when `install.sh --hooks` runs again.
- The first step of the skill checks for the role hook. When it is
  missing, the coordinator tells the user to type `/coordinator` again
  after a compaction. My call: graceful handling.

### Rules from the recorded cases

My calls, 2026-11-02, each from a case in `.context/coordinator-skill/cases.md`:

- A failed create is an item that quotes the error, unless it names a
  wait. No child runs in the coordinator's workspace (S2, S3).
- A usage limit is an item with its reset time, with no retry loop (R2).
  A lost orchestrator gets one new session, as its one retry (R4).
- On `waiting:` send nothing, unless the same list stays over cycles or
  a sleep (R6). On a reader failure, report it and send nothing (R11).
- An answer that the user gave a child directly is not sent again (I2).
  A child scope wider than the user's request is an item first (D1).
- A change in the coordinator's own repository gets a child too, and the
  merge check decides for every child. It never does a child's work (O1,
  D4, O2). It starts no wait. "status?" starts a full cycle (W1, W3).

## Milestone 1: Documentation

Depends on: none

The README states the coordinator and the role hook for the work below.

- [x] Add the `coordinator` row to the skills table of `README.md`.
- [x] Add a section "Coordinating several changes" after "The flow of a
      feature". Say what the coordinator is, how to start it, what it
      does alone, what goes to the user, that it merges into `main`,
      that the role hook keeps its role, and that waking is outside it.
- [x] Say in "Keep an install current" that `install.sh --hooks` adds
      the role hook. Name `scripts/role-hook.sh` in "Layout".

## Milestone 2: Reader

Depends on: 1

The reader of PR #37 comes over with its tests and gets the stall result.

- [x] Copy `last-report.sh` and `conductor-pages.sh` to
      `skills/coordinator/scripts/` from the scripts of
      `skills/conductor-section-workspace-coordinator/` on
      `origin/calummoore/conductor-workspace-coordinator-skill`.
      Branch: `conductor/coordinator-skill-m2-reader`.
- [x] Copy the 13 `last_report` tests, the `list_all` test, and their
      helpers from `tests/coordinator_scripts_test.sh` on that branch.
      Branch: `conductor/coordinator-skill-m2-reader`.
- [x] Add `error: stalled: <cause>`, with a test, and a test that a long
      `working` turn without an error stays `pending: working`.
      Branch: `conductor/coordinator-skill-m2-reader`.
- [x] Run `tests/run.sh`, and `shellcheck -x` on both scripts.
      Branch: `conductor/coordinator-skill-m2-reader`.

## Milestone 3: Role hook

Depends on: 1

The role hook and its marker script, installed by `install.sh --hooks`.

- [ ] Add `role.sh` and `scripts/role-hook.sh`, as the design says.
- [ ] Add the hook entries to `install.sh --hooks` and `--uninstall`.
- [ ] Add `tests/role_hook_test.sh`: no marker, the marker of another
      session, each event, a bad session id, bad input, and a marker
      that `role.sh start` wrote. Update the hook checks in
      `tests/install_test.sh`.
- [ ] Run `tests/run.sh`, and `shellcheck -x` on the new scripts.

## Milestone 4: Skill text

Depends on: 2, 3

The skill text, written from the recorded cases.

- [x] Record the cases in `.context/coordinator-skill/cases.md`, as the
      `writing-skills` skill says, from the sessions `ef75f239` (README
      fan-out), `75b657aa` (PR #37), and `eee1022e` (the brainstorm of
      2026-10-30). Give the place, what the agent did, and its words.
- [ ] Add the age of the last event to `pending: working` in the reader,
      with tests, by the `non-ui implementor`.
- [ ] Replace the stub `SKILL.md` with the skill, in about 150 lines.
      Add `references/cycle.md`, `templates/state.md`, and
      `templates/messages.md`, from the parts of PR #37 that still apply.
- [ ] Walk each case with the final text, until each case gets the
      instruction that changes its outcome. Run `scripts/check.sh`.

## Milestone 5: Smoke test

Depends on: 3, 4

It tests the hook and the reader in live sessions.

- [ ] Stop the update loop of `~/.futex/skills`, and run
      `scripts/install.sh --hooks` from this checkout.
- [ ] In a scratch Claude session, run `role.sh start`, send a prompt,
      `/compact`, and `/clear`, and check the reminder after each. Add
      `PostCompact` when `SessionStart` does not fire after `/compact`.
      Check that `role.sh stop` ends the reminder.
- [ ] Run the reader on a finished, a working, and a failed session.
- [ ] Save the evidence in `.context/coordinator-skill/smoke.md`. Archive
      the scratch session, and restore the install and its loop.

## Milestone 6: Verification, commit, review, and pull request

Depends on: 1, 2, 3, 4, 5

The complete checks, the review, and the pull request.

- [ ] Run `scripts/check.sh`, `tests/run.sh`, `shellcheck -x` on each
      changed script, and `git diff --check`. Commit, and push.
- [ ] Review the diff against `origin/main` with the
      `implementation-review` skill. Fix the `fix now` findings, record
      follow-up items for the rest, re-review once, and report.
- [ ] Delete this plan when "Deleting the plan" of `plans` says.
- [ ] Open the pull request with the decisions, the design calls, a plan
      permalink, and the follow-up items. Say that an install gets the
      skill from `update.sh`, and the role hook from `install.sh --hooks`.

## Post-merge follow-up (non-blocking)

- [ ] Ask the user whether to close PR #37, after its follow-up items that
      still apply move here, with items for its items 15 and 3.
- [ ] Record the cases of the first real coordinator run.

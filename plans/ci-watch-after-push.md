# Watch CI after each push

Status: Active. On branch `calummoore/ci-failure-auto-fix-agent`, no pull
request yet. The pull request that completes the work deletes this plan, as the
`plans` skill says.

The `finish-work` skill ends work with a local gate, a push, a review, a pull
request, and a report. No skill tells the agent to watch CI. So an agent can
report "done" while CI is red or still running, and the user must prompt it. An
unrelated failure blocks each open branch until someone fixes it by hand.

The change adds a CI step to `finish-work`. After each push, the agent waits
for the CI runs of the pushed commit with a new script. A failure of the branch
gets a fix in the branch. A flaky test gets one rerun. An unrelated failure
gets one fix pull request (fix PR) from `main`, after a search for another
owner. Any other failure goes to the user. An agent merges a fix PR into `main`
only when the repository's `AGENTS.md` allows it and the guardrails of the
design hold. The change does not cover CI that is not GitHub Actions, or runs
that no session watches, such as bot branches and scheduled runs.

## Decisions

The user decided on 2026-11-01, in Conductor workspace #207, and gave no
reason. Each reason below is the reason of the recommendation.

- Item 1, how CI gets watched and acted on: option A, a skill step and a script
  in the agent's own session. Reason: it works in Claude Code and Codex and
  needs no secret. The agent that knows the branch makes the fix. Rejected:
  - B: option A, plus Claude Code hooks after `git push` and on Stop. It worked
    in Claude Code only, and its code runs on every machine. A wrong block can
    trap a session. It can follow if agents skip the step.
  - C: a CI agent in each repository that a failed run starts. It needed an API
    key secret and a workflow in each repository. It did not know the plan or
    the review of the branch.
  - Left out: the section coordinator of open PR #37, which covers only
    coordinated sections. GitHub Copilot "Watch and fix", which does not apply
    the fix rule. A report of the CI result only, which fixes nothing. A merge
    queue, which adds a gate and does not stop flaky tests.
- Item 2, who merges a fix PR: option D. The agent merges it into `main` only
  in a repository whose `AGENTS.md` turns agent merges on. Elsewhere the user
  merges it, as today. Reason: a push to `main` deploys in accounting, firna,
  and terminal, so a human review stays there. Rejected:
  - A: the user merges every fix PR. Each open branch stays red until then.
  - B: the agent merges the fix branch into its own branch only. The other
    branches stay red, and the feature PR shows the fix lines.
  - C: agent merges in every repository. A change can reach `main`, and deploy,
    with no human review.

The plan adds no open decision, so no options check ran.

## Check repository and cases

Accounting is the check repository of the `writing-skills` skill, because it
holds the one real fix PR. The cases to walk are accounting #740, #741, #739,
and #517, and redloop PR #1. Their facts are in `.context/ci-watch/notes.md`.

Contract owners: the [README](../README.md), the
[`finish-work` skill](../skills/finish-work/SKILL.md) and its new reference,
and the [`AGENTS.md` template](../skills/agents-md/templates/AGENTS.md).

## Design

Each "Design call" is a call of the agent under the decision test, made on
2026-11-01.

### The CI step

`finish-work` gets a new step 7, "CI", before the report. The report becomes
step 8, and "After the merge" becomes step 9. Step 7 says: after each push, run
the script in the background and go on. When a run fails, act as
`references/ci.md` says. Before the report, wait for the CI of the last push.
The description gains "after a push that starts CI" and "when a CI run fails or
still runs". The report step and the checklist each gain one line.

- Design call: the rule goes into `finish-work`, because it loads at each push.
  A new skill would add a description to every session.
- Design call: the PR still opens only when the implementation is complete, as
  PR #28 chose. So the first CI run often comes after the PR opens.
- Design call: step 9 points to the exception of the fix pull request, where it
  says to work on a follow-up item only on request.
- Design call: the skill text writes "fix pull request" in full, as
  `finish-work` writes "pull request".
- Design call: step 6 of the `implementation-review` skill names the CI step
  among the next steps, so that a review does not skip it.

### The wait script

`skills/finish-work/scripts/ci-wait.sh` waits for the GitHub Actions runs of
one commit and prints their results. It runs on Linux, and on macOS with bash
3.2.

```text
ci-wait.sh [--timeout <minutes>] [--grace <seconds>] [--interval <seconds>]
           [--repo <owner/name>] [<commit>]
```

- `<commit>` defaults to `HEAD`, and `git rev-parse` resolves it. With
  `--repo`, give the full SHA, because the local clone may not have it.
- It lists the runs with `gh run list --commit <sha>`. Design call: it filters
  them with `gh --jq`, because not every machine has `jq`.
- It polls every `--interval` seconds, 30 by default. It ends when the complete
  run list stayed the same for the grace period, and in two polls in a row.
  Design call of 2026-11-02, review finding 3: a run that an opening, a
  change to ready, a rerun, or another run starts late still counts.
- It prints one line for each run: the conclusion, the workflow, and the URL.
  A run passes when its conclusion is `success`, `skipped`, or `neutral`. For
  a run that did not pass, it adds each failed job and its first failed step.
- Exit 0: every run passed. Exit 1: a run ended with another conclusion, such
  as `failure`, `cancelled`, or `action_required`.
- Exit 2: a run was pending at the deadline, 60 minutes by default. Design
  call: the slowest median run found takes 15 minutes, and a hung runner must
  not hold the session.
- Exit 3: no run started within `--grace` seconds, 120 by default. The script
  prints `no CI run for <sha>`.
- Exit 4: a usage error, no `gh`, or three failed `gh` calls in a row. A single
  failed call prints a warning, and the script polls again. Design call: a
  broken credential must not hold the session for an hour.
- The script keeps no state. When a tool stops a long command, the agent runs
  the script again.

### The test

`tests/ci_wait_test.sh` runs the script against a fake `gh` on `PATH`. The fake
serves one JSON file of the scenario for each `gh run list` call. It applies
the `--jq` filter of the call with `jq`, so the test also checks the filters.
The file reports a skip when `jq` is missing. Each case runs in a temporary git
repository, with `--interval 0`. A deadline of 0 is a timeout that the test
expects to expire, and no case asserts elapsed time. Each case names its break:

The six cases cover running and late runs, the first failed step of each
failed job, the deadline, the grace period, one failed `gh` call, and three
failed calls. The comment of each case in `tests/ci_wait_test.sh` names it.

### The reference

`skills/finish-work/references/ci.md` holds the procedure, in the order of
the work: watch, read a failure, find the cause, fix an unrelated failure,
and report. Its design calls, of 2026-11-01:

- A newer push replaces the commit to watch, because only the last commit
  decides the merge.
- A cancelled run of the last commit gets one rerun. An `action_required`
  run waits for a person, so it goes to the user.
- The cause test follows the order of the user's message. A failure in a
  job, step, test, or file that the diff adds or changes is the branch's,
  when the error is in the branch's version of the file. Every other
  failure gets one rerun. A pass makes the test flaky. A second failure is
  unrelated only when the job also fails on the last `origin/main` commit.
  The first draft compared with `origin/main` first. Its case walk misfiled
  redloop #1 and firna #1360.
- The comparison reads the run of the last `origin/main` commit, because an
  old run of the job hides the state of `main`.
- The branch merges the base branch of its pull request, as the `git-merge`
  skill says. A primary branch gets the fix only when its orchestrator
  merges `main`.
- One rerun for each pushed commit, because more reruns hide a flaky test.
  An unrelated flaky test keeps its follow-up item and gets no fix PR,
  because the user asked for a fix PR only when a rerun does not help.
- A fix in the branch that needs a credential, a secret, or a runner waits
  for the user, as redloop #1 shows.
- A change of a checksum, a dependency version, or a download URL makes the
  merge wait, not the fix.
- The claim is an empty commit pushed to `ci-fix/<job>-<step>`, with a draft
  PR. The commit message holds the agent's branch name, so two claims never
  share a commit. A push to an existing branch fails.
- The fix workspace pushes to the claim branch, because Conductor names the
  workspace branch from the workspace name.
- The agent of the fix PR merges it, after `gh pr ready`, and watches the
  merge commit, because a push to `main` can deploy. It merges only when the
  setting on `origin/main` is on, the fix rule allows the fix, no finding of
  its review waits for the user, its CI is green, and its diff changes no
  checksum, dependency version, download URL, secret, or workflow file. The
  setting comes from `origin/main`, so a fix PR cannot turn it on.
- The agent of the original branch waits at most 60 minutes for the fix PR.
- A follow-up item on `origin/main` that records the failure goes to the fix
  PR, which deletes it. No new item records a failure that a fix PR owns.
- For CI that is not GitHub Actions, the report says that the agent cannot
  watch it.

The fixes of review round 1 added these design calls, on 2026-11-02:

- The agent watches again after each change that can start CI: a push, the
  opening of the pull request, and a change from draft to ready. The merge
  step marks the fix PR ready before its last watch. Review finding 1.
- Before the label of a failure of the branch or of an unrelated failure,
  and before a claim, the agent checks the base branch. When the branch is
  behind, it merges, pushes, watches, and starts again, at most three times.
  A pass on a rerun makes a flaky test without this check. Review finding 2.
- The `AGENTS.md` of this repository gets `## CI` with `Agent merges: off`,
  because `main` here reaches every machine within minutes of a merge.

The fixes of review round 2 added these design calls, on 2026-11-02:

- The script reads the time with `date +%s`, so that its test can use a fake
  clock. Review finding 3.
- The base check fetches the base branch and `main`. After a second failure,
  the agent reads the job on both fresh commits, and only a run that started
  after the failed run counts. A failure only of the base gets no fix PR and
  no fix in the branch, and goes under **Open**. Review finding 4.
- Exit 3 with an open pull request: the agent checks it for a merge conflict,
  because a conflict stops pull request CI.

## Milestone 1: Documentation

Depends on: none

- [x] Add "after a push that starts CI, when a CI run fails" to the
      `finish-work` row of the Skills table in `README.md`.
- [x] Add a CI stage after the pull request stage of "The flow of a feature":
      the orchestrator, with `finish-work`, `testing`, `git-merge`, and
      `delegating`. Renumber the last two stages. Design call: the row also
      names `git-commit` and `plans`, as "Review and fix" does for that work.
- [x] In "How the pieces fit", add agent merges of fix PRs to the choices that
      a skill leaves to the repository.

## Milestone 2: The wait script

Depends on: none

- [x] Add `skills/finish-work/scripts/ci-wait.sh` as the design says.
- [x] Add `tests/ci_wait_test.sh` with the six cases of the design. See each
      case fail on an assertion before the script passes it.
- [x] Run `scripts/check.sh`, `shellcheck -x` on both files, and
      `tests/run.sh`. Run the new test file 10 times, and save the pass counts
      under `.context/ci-watch/`.
- [x] Smoke test. Run the script on `origin/main` of this repository, and
      expect exit 0. Run it with `--repo futex-ai/accounting` on the commit of
      run 41053636670. Expect exit 1, with `Rust tests` and `Build HMRC LTS`.
      Save the output under `.context/ci-watch/`. Evidence:
      `.context/ci-watch/m2-*.txt` and `m2-break-proof.md`.

## Milestone 3: The CI reference and step

Depends on: 2

- [x] Write `skills/finish-work/references/ci.md` as the design says.
- [x] Edit `skills/finish-work/SKILL.md`: the description, the first paragraph,
      step 7, the numbers of steps 8 and 9, the report line, and the checklist
      line.
- [x] Walk each case of "Check repository and cases" with the final text, as
      the `writing-skills` skill says. Fix the text until each walk gives the
      right action. Save the walk under `.context/ci-watch/case-walk.md`.
- [x] Run `scripts/check.sh` with no new warning: the `finish-work`
      description under 500 characters, and its file under 200 lines.

## Milestone 4: The agent-merge setting

Depends on: none

Split from Milestone 3 on 2026-11-01, for the small-milestone rule of `plans`.

- [x] In the `AGENTS.md` template, add a `## CI` section after `## Commands`,
      with `Agent merges: off`. Its note says that only the user turns it on,
      with a merge method, as in `on, squash`. Design call: `gh pr merge`
      needs a method, and each repository has its own. Design call: the note
      stays a placeholder, and the reference gives the form of the line.
- [x] In `skills/agents-md/SKILL.md`, name the setting in the list of
      repository-specific rules. A new `AGENTS.md` keeps it `off` until the
      user turns it on.
- [x] In `skills/plans/references/follow-up-items.md`, add one exception to
      "Work on an item only when the user asks for it". A fix PR for an
      unrelated CI failure works on the item that records the failure, and
      deletes it.

## Milestone 5: Verification, commit, review, and pull request

Depends on: 1, 2, 3, 4

The orchestrator keeps the gate, the review, and the pull request. The new
step 7 applies to the CI that starts when the pull request opens.

- [x] Run the checks of the CI workflow: `scripts/check.sh`, `shellcheck -x` on
      every script, `tests/run.sh`, and the trailing-whitespace check.
- [x] Commit with Conventional Commits and push the branch.
- [x] Review the complete local diff against `origin/main` with the
      `implementation-review` skill after the push. Report the findings, then
      apply the fix rule: fix the `fix now` findings, record follow-up items
      under `plans/follow-ups/` for the rest, re-review once, and report.
- [ ] Delete this plan when the `plans` skill says, under "Deleting the plan".
- [ ] Open the pull request. Its description gives the decisions and design
      calls with their dates, a permalink to this plan, and the new follow-up
      items. It says that `scripts/update.sh` brings the change to an install.

## Post-merge follow-up (non-blocking)

- [ ] Walk the next real CI failure in a futex repository with the merged text.
      Check that the agent takes the action that the reference gives.

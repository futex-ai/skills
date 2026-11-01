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
- It polls every `--interval` seconds, 30 by default. It ends when two polls in
  a row show the same runs, and each run is `completed`. Design call: the
  second poll catches a workflow that another workflow starts.
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

1. `test_waits_for_running_and_late_runs`: exit 0 after a run in progress, a
   skipped run, and a late run. Break: an end at the first complete poll, or a
   skipped run counted as a failure.
2. `test_names_the_first_failed_step_of_each_failed_job`: exit 1, with
   `Rust tests` at `Build HMRC LTS` and `Verify` at `Verify required jobs`.
   Break: a wrong job filter.
3. `test_stops_at_the_deadline_with_a_pending_run`: exit 2 with `--timeout 0`.
   Break: no deadline.
4. `test_reports_no_run_after_the_grace_period`: exit 3 with `--grace 0`.
   Break: a push without CI reported as a pass.
5. `test_polls_again_after_a_failed_gh_call`: exit 0 and a warning. Break: a
   stop on one error.
6. `test_stops_after_three_failed_gh_calls`: exit 4. Break: an endless retry
   loop.

### The reference

`skills/finish-work/references/ci.md` holds the procedure.

1. Watch. Run the script on the pushed commit. A newer push replaces the commit
   to watch. Design call: only the last commit decides the merge. Exit 3 means
   that the push starts no CI. Report exit 2 under **Checks** as pending.
2. Read a failure with `gh run view <run> --log-failed`. Start at the first
   failed step. Skip a summary job, such as "Verify required jobs", because it
   only repeats the other failures.
3. Find the cause.
   - When the branch is behind `origin/main`, merge `main` first with the
     `git-merge` skill. PR CI tests the branch merged with `main`.
   - A failure belongs to the branch when the job passes on `origin/main` and
     fails on the branch. Read the last run of the job on `main`. When `main`
     has none, run the failing command on `origin/main`.
   - Fix a failure of the branch in the branch, as "When a test fails" in the
     `testing` skill says. Commit, push, and watch again.
   - Otherwise, rerun the failed jobs once with `gh run rerun <run> --failed`,
     and watch again. A second failure is an unrelated failure. Design call:
     more reruns hide a flaky test.
   - A pass on the rerun makes the test flaky, and the flaky-test rules of the
     `testing` skill apply. Design call: an unrelated flaky test keeps its
     follow-up item and gets no fix PR. The user asked for a fix PR only when a
     rerun does not help.
   - A `cancelled` run: watch the newer commit when one exists. Otherwise,
     rerun it once. An `action_required` run waits for a person, so ask the
     user.
   - After three failed fixes of one failure, ask the user, as the `testing`
     skill says.
4. Fix an unrelated failure.
   1. Apply the decision test to the fix. The fix waits for the user when it
      needs a credential, a secret, a runner, a skipped test, or a gate change.
      It also waits when the cause stays unknown. Give the failure text, the
      rerun outcome, and the suspected source. Record a follow-up item.
   2. Search for an owner. Search the open PRs, the remote branches under
      `ci-fix/`, the Conductor workspaces named `ci-fix:`, and the follow-up
      items on `origin/main`. When a PR or a workspace owns the failure, name
      it in the report, and wait as the last step says.
   3. Claim the failure. Push an empty commit on `origin/main` to a new branch
      `ci-fix/<job>-<step>`. Open a draft PR from it, titled
      `fix(ci): <failure>`, with the failure text. A rejected push means that
      another agent holds the claim, so search again. When that claim is for
      another failure, add the test name to the branch name. Design call: each
      agent sees a draft PR from any machine, and a push to an existing branch
      fails, so two agents cannot both claim.
   4. Start the fix in its own workspace, as the `delegating` skill says. The
      workspace starts from the claim branch, is named `ci-fix: <job>`, and
      runs the `default orchestrator` action. Its prompt gives the failure
      text, the run URL, the rerun outcome, the suspected source, the claim
      branch, and the draft PR. The agent follows `finish-work` on the claim
      branch. Outside Conductor, a worktree agent does the fix.
   5. Merge. The agent of the fix PR merges it into `main` only when all of
      these hold:
      - The `## CI` section of `AGENTS.md` says `Agent merges: on` and names
        the merge method.
      - The fix rule lets the agent make the fix without the user.
      - No finding of its review waits for the user.
      - Its CI is green.
      - Its diff changes no checksum or digest, dependency version or lockfile,
        download URL, secret, or CI workflow file.

      Then the agent merges the PR with the named method and deletes the
      branch. It watches the CI runs of the merge commit, because a push to
      `main` can deploy. It reports a failure there to the user at once. When a
      condition fails, it marks the PR ready, reports it to the user, and
      stops. Design call: the agent that owns the PR runs its review and its
      CI, so it merges.
   6. Wait. The agent of the original branch waits at most 60 minutes for the
      fix PR to merge. Then it merges `main` into its branch with the
      `git-merge` skill, pushes, and watches again. When the time ends first,
      it reports the red CI under **Open**, with the fix PR.
   - Design call: no follow-up item records a failure that a fix PR owns. The
     fix PR is the record. An item in the feature branch would stay after the
     fix.
5. Report. **Checks** gives each CI run of the last push: the workflow, the
   result, each rerun, and each fix commit. An unrelated failure gives its fix
   PR, or the follow-up item that waits for the user. Design call: for CI that
   is not GitHub Actions, the report says that the agent cannot watch it. Every
   futex repository uses GitHub Actions.

## Milestone 1: Documentation

Depends on: none

- [ ] Add "after a push that starts CI, when a CI run fails" to the
      `finish-work` row of the Skills table in `README.md`.
- [ ] Add a CI stage after the pull request stage of "The flow of a feature":
      the orchestrator, with `finish-work`, `testing`, `git-merge`, and
      `delegating`. Renumber the last two stages.
- [ ] In "How the pieces fit", add agent merges of fix PRs to the choices that
      a skill leaves to the repository.

## Milestone 2: The wait script

Depends on: none

- [ ] Add `skills/finish-work/scripts/ci-wait.sh` as the design says.
- [ ] Add `tests/ci_wait_test.sh` with the six cases of the design. See each
      case fail on an assertion before the script passes it.
- [ ] Run `scripts/check.sh`, `shellcheck -x` on both files, and
      `tests/run.sh`. Run the new test file 10 times, and save the pass counts
      under `.context/ci-watch/`.
- [ ] Smoke test. Run the script on `origin/main` of this repository, and
      expect exit 0. Run it with `--repo futex-ai/accounting` on the commit of
      run 41053636670. Expect exit 1, with `Rust tests` and `Build HMRC LTS`.
      Save the output under `.context/ci-watch/`.

## Milestone 3: The CI reference and step

Depends on: 2

- [ ] Write `skills/finish-work/references/ci.md` as the design says.
- [ ] Edit `skills/finish-work/SKILL.md`: the description, the first paragraph,
      step 7, the numbers of steps 8 and 9, the report line, and the checklist
      line.
- [ ] Walk each case of "Check repository and cases" with the final text, as
      the `writing-skills` skill says. Fix the text until each walk gives the
      right action. Save the walk under `.context/ci-watch/case-walk.md`.
- [ ] Run `scripts/check.sh` with no new warning: the `finish-work`
      description under 500 characters, and its file under 200 lines.

## Milestone 4: The agent-merge setting

Depends on: none

Split from Milestone 3 on 2026-11-01, for the small-milestone rule of `plans`.

- [ ] In the `AGENTS.md` template, add a `## CI` section after `## Commands`,
      with `Agent merges: off`. Its note says that only the user turns it on,
      with a merge method, as in `on, squash`. Design call: `gh pr merge`
      needs a method, and each repository has its own.
- [ ] In `skills/agents-md/SKILL.md`, name the setting in the list of
      repository-specific rules. A new `AGENTS.md` keeps it `off` until the
      user turns it on.
- [ ] In `skills/plans/references/follow-up-items.md`, add one exception to
      "Work on an item only when the user asks for it". A fix PR for an
      unrelated CI failure works on the item that records the failure, and
      deletes it.

## Milestone 5: Verification, commit, review, and pull request

Depends on: 1, 2, 3, 4

The orchestrator keeps the gate, the review, and the pull request. The new
step 7 applies to the CI that starts when the pull request opens.

- [ ] Run the checks of the CI workflow: `scripts/check.sh`, `shellcheck -x` on
      every script, `tests/run.sh`, and the trailing-whitespace check.
- [ ] Commit with Conventional Commits and push the branch.
- [ ] Review the complete local diff against `origin/main` with the
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

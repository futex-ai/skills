# CI

This file gives the procedure of the CI step in the `finish-work` skill.
It covers the GitHub Actions runs of each commit that you push. A run that
no session watches is outside it, such as a run on a bot branch or a
scheduled run.

## Watch

To watch a commit, run `scripts/ci-wait.sh [<commit>]` of the
`finish-work` skill in the background. The commit is `HEAD` by default.

The script waits for every run of the commit. It ends only when no run or
status changed for the grace period, 120 seconds by default, and in two
polls in a row. So a run still joins the watch when a pull request
opening, a change to ready, a rerun, or another run starts it late. It
prints one line for each run: the result, the workflow, and the URL. Under
a run that did not pass, it names each failed job and its first failed
step.

- Watch the last commit after each change that can start CI. These changes
  are a push, the opening of the pull request, and a change from draft to
  ready. A result from before the last change does not count. Only the
  runs of the last commit decide the merge.
- The script keeps no state. When a tool stops it, run it again on the
  same commit.
- Some repositories run CI on pull requests only. There, a push before the
  pull request opens starts no run.

Act on the exit status of the script:

- 0: every run passed. Go on.
- 1: a run ended without a pass, for example with `failure` or
  `cancelled`. Read the failure, as the next section says.
- 2: a run still ran at the deadline, 60 minutes by default. Report it
  under **Checks** as pending.
- 3: no run started in the grace period, 120 seconds by default. When a
  pull request is open, check it for a conflict with
  `gh pr view --json mergeable --jq .mergeable`. Check again while it says
  `UNKNOWN`. `CONFLICTING` means that CI cannot start. Then merge the base
  branch, as step 1 of "Find the cause" says, and watch again. Otherwise,
  the change starts no CI.
- 4: a usage error, no `gh`, or three failed `gh` calls in a row. Correct
  the call. Run the script again. When it fails again, report the blocker
  under **Checks**.

## Read a failure

First read the conclusion of the run:

- A `cancelled` run: watch the newer commit when one exists. Otherwise,
  rerun the run once with `gh run rerun <run>`.
- An `action_required` run waits for a person. Ask the user.
- Any other run: read the log of its failed jobs.

```sh
gh run view <run> --log-failed
```

The run id is the last number in the run URL. Start at the first failed
step that the script names. Find its first error there. Skip a summary
job, such as "Verify required jobs". It only repeats the other failures.

## Find the cause

1. This section gives each failure one label: a failure of the branch, a
   flaky test, or an unrelated failure. Before you label a failure as one
   of the branch or as unrelated, check the base branch. Check it before a
   claim too. A pass on a rerun makes a flaky test without this check. The
   command takes the base branch of the pull request, or `main` when the
   branch has no pull request:

   ```sh
   base=$(gh pr view --json baseRefName --jq .baseRefName 2>/dev/null \
     || echo main)
   git fetch origin "$base" main
   git rev-list --count "HEAD..origin/$base"
   ```

   A count above 0 shows that the branch is behind. Then merge the base
   branch with the `git-merge` skill. Push the merge, and watch the new
   commit. Then start this section again with the result of that watch. A
   rerun keeps the commit of its first run, so it cannot test a merge.

   After three such merges for one failure, use the last run. A busy base
   branch then cannot hold you in a loop.

2. A failure belongs to the branch when its job, step, test, or file is
   one that the diff adds or changes. A file counts only when the error is
   in its version on the branch. List the files of the diff:

   ```sh
   git diff --name-only "origin/$base...HEAD"
   ```

   Fix such a failure in the branch, as "When a test fails" in the
   `testing` skill says. Commit, push, and watch again. A flaky test that
   the diff adds or changes follows the flaky-test rule of the `testing`
   skill. A fix that needs a credential, a secret, or a runner waits for
   the user. Ask the user, with the failure text. After three failed fixes
   of one failure, ask the user, as the `testing` skill says.

3. Otherwise, rerun the failed jobs once with `gh run rerun <run> --failed`.
   Watch again.

   - A pass on the rerun makes the test flaky. An unrelated flaky test gets
     the follow-up item that the `testing` skill asks for. It gets no fix
     pull request.
   - Do not rerun it again, because more reruns hide a flaky test.
   - After a second failure, check the base branch again, as step 1 says.
     Then read the failing job on two fresh commits, `origin/$base` and
     `origin/main`. When the base is `main`, they are one commit.

     ```sh
     gh run list --commit "$(git rev-parse <ref>)" --workflow <workflow> \
       --event push --json databaseId,createdAt,conclusion
     gh run view <run>
     ```

     A pass counts only from a run of the job that started after the
     failed run of the branch. A pull request run of the base does not
     count, because it tests the base merged with another branch. Without
     such a run, run the failing command on that commit in a separate
     worktree. The failed step in the workflow file gives the command:

     ```sh
     git worktree add --detach <dir> <ref>
     git worktree remove <dir>      # after the run
     ```

   - When the job fails on both commits, the failure is unrelated. Go to
     "Fix an unrelated failure".
   - When it fails on the base and passes on `main`, the failure comes from
     the base. Open no fix pull request. Make no fix in the branch. Report
     the red CI under **Open**, with both commits.
   - When it passes on the base, the failure belongs to the branch. Fix it
     in the branch, as step 2 says.

## Fix an unrelated failure

An unrelated failure gets one fix in its own pull request from `main`: the
fix pull request. One fix there reaches every open branch.

1. Apply the decision test of the `decisions-and-findings` skill to the
   fix. The fix waits for the user when it needs a credential, a secret, a
   runner, a skipped test, or a gate change. It also waits when the cause
   stays unknown. When the fix waits, report the failure text, the rerun
   outcome, and the suspected source. Record them in a follow-up item, as
   the `plans` skill says.

   A change of a checksum, a dependency version, or a download URL does
   not make the fix wait. It makes the merge wait, as the merge step below
   says.

2. Search for an owner. An owner is an open pull request or a workspace
   that fixes the failure. Search the open pull requests, the remote
   branches under `ci-fix/`, the Conductor workspaces named `ci-fix:`, and
   the follow-up items on `origin/main`:

   ```sh
   gh pr list --state open --search "<failed step>"
   git ls-remote --heads origin 'ci-fix/*'
   conductor workspace list --name "ci-fix:" --repo <repository>
   git fetch origin main
   git grep -il "<failed step>" origin/main -- plans/follow-ups
   ```

   When an owner exists, name it in the report. Then wait, as the last step
   says. When a follow-up item records the failure, give the item to the
   fix pull request. That pull request deletes the item. When the item
   waits for the user, the failure waits too. Name the item in the report.

3. Claim the failure. First check the base branch again, as step 1 of
   "Find the cause" says. Then push an empty commit on `origin/main` to a
   new branch `ci-fix/<job>-<step>`. Open a draft pull request from it,
   titled `fix(ci): <failure>`, with the failure text:

   ```sh
   claim=$(git commit-tree 'origin/main^{tree}' -p origin/main \
     -m "chore(ci): claim <failure> for <your branch>")
   git push origin "$claim:refs/heads/ci-fix/<job>-<step>"
   gh pr create --draft --base main --head ci-fix/<job>-<step> \
     --title "fix(ci): <failure>" --body-file <file>
   ```

   Write the job and the step in lowercase kebab-case, as in
   `ci-fix/rust-tests-build-hmrc-lts`. Your branch name in the commit
   message makes each claim commit unique. A push to an existing branch
   fails, so two agents cannot both claim. A rejected push means that
   another agent holds the claim. Then search again. When that claim is for
   another failure, add the test name to the branch name.

4. Start the fix in its own workspace, as the `delegating` skill says. The
   workspace starts from the claim branch, is named `ci-fix: <job>`, and
   runs the `default orchestrator` action:

   ```sh
   conductor workspace create --branch ci-fix/<job>-<step> \
     --name "ci-fix: <job>" --agent <agent> --model <model> \
     --effort <effort> --message-file <prompt>
   ```

   The prompt gives the failure text, the run URL, the rerun outcome, the
   suspected source, the claim branch, and the draft pull request. It names
   the follow-up item that records the failure, when one exists. It tells
   the agent to push each commit to the claim branch, with
   `git push origin HEAD:ci-fix/<job>-<step>`. It tells the agent to follow
   the `finish-work` skill, and then the merge step below. Outside
   Conductor, a worktree agent does the fix.

5. Merge. The agent of the fix pull request merges it into `main` only
   when all of these hold:

   - The `## CI` section of `AGENTS.md` on `origin/main` has the line
     `Agent merges: on, <method>`. The method is `merge`, `squash`, or
     `rebase`, as `gh pr merge` names it. Only the user turns the setting
     on. The setting on the fix branch does not count, so a fix pull
     request cannot turn it on.
   - The fix rule lets the agent make the fix without the user.
   - No finding of its review waits for the user.
   - Its diff changes no checksum or digest, dependency version or
     lockfile, download URL, secret, or CI workflow file.
   - Each CI run of its last commit passed, in a watch that started after
     the pull request became ready.

   Check the conditions other than CI first:

   ```sh
   git fetch origin main
   git show origin/main:AGENTS.md
   ```

   When they hold, mark the pull request ready. Then watch the CI of its
   last commit, because readiness can start more runs. Merge only when
   each run of that watch passed. The merge command also deletes the
   branch. Then watch the merge commit, because a push to `main` can
   deploy. Report a failure there to the user at once.

   ```sh
   gh pr ready <number>
   scripts/ci-wait.sh
   gh pr merge <number> --<method> --delete-branch
   git fetch origin main
   merge=$(gh pr view <number> --json mergeCommit --jq .mergeCommit.oid)
   scripts/ci-wait.sh "$merge"
   ```

   When a condition fails, mark the pull request ready. Report it to the
   user. Then stop.

6. Wait for the merge. As the agent of the branch, wait at most 60 minutes
   for the fix pull request to merge. Check its state every 5 minutes, with
   `gh pr view <number> --json state`.

   When it merges, merge the base branch of your pull request into the
   branch, with the `git-merge` skill. Push, and watch again. When the base
   branch is a primary branch of the `delegating` skill, it gets the fix
   only when its orchestrator merges `main`. Until then, report the red CI
   under **Open**, with the fix pull request. Report it there too when the
   time ends first.

Add no follow-up item for a failure that a fix pull request owns. The fix
pull request is the record. An item in your branch would stay after the
fix.

Example: in accounting pull request #740, the script named
`Rust tests: Build HMRC LTS`. The log said `LTS8.3.zip: FAILED`, because
HMRC had replaced the file at the same URL. The build failed again on the
next run of the branch and on `origin/main`, so the failure was unrelated.
The fix pull request, #741, pinned the new SHA-256. Its diff changes a
checksum, so the user merged it. Then #740 merged `main`, and its CI
passed.

## Report

Under **Checks**, give each CI run of the last commit: the workflow, the
result, each rerun, and each fix commit.

- Report a run that still ran at the deadline as pending.
- Report a commit that has no run as "no CI run".
- Report a script that could not run, with its error.
- An unrelated failure gives its fix pull request, or the follow-up item
  that waits for the user.
- A red run that waits for a fix pull request, or for a fix in the base
  branch, also goes under **Open**.
- For CI that is not GitHub Actions, say that you cannot watch it.

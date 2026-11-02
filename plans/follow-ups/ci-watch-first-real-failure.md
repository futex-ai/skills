# Walk the first real CI failure with the CI step

- **Severity:** Low. **Effort:** Small. **Confidence:** Medium. **Harder later:** No.
- **Kind:** Post-merge task.
- **Added:** 2026-11-02, from the branch `calummoore/ci-failure-auto-fix-agent` and its plan `ci-watch-after-push.md`.
- **Location:** `skills/finish-work/references/ci.md` and `skills/finish-work/scripts/ci-wait.sh`.
- **Reason:** The task needs a real CI failure in a futex repository after the merge, and none can happen before it.

**Background:** The `finish-work` skill has step 7, "CI". After each change
that can start CI, the agent runs `scripts/ci-wait.sh` of that skill on the
last commit. A change that can start CI is a push, the opening of a pull
request, or a change from draft to ready. On a failure, `references/ci.md`
gives the action: a fix in the branch, one rerun for a flaky test, a fix
pull request from `main` for an unrelated failure, or a report to the user.
Before the merge, the text was checked only against recorded cases:
accounting pull requests #740, #741, #739, #724, and #517, redloop pull
request #1, and firna pull request #1360.

**Task:** When the first real CI failure happens in a futex repository
after the merge, read the session of the agent that met it. Check that the
agent watched CI after each push, gave the failure the right label, and
took the action that the reference gives. Correct the text where the agent
took another action.

**Impact if no action:** A gap in the text stays hidden until an agent acts
on a real failure in a wrong way, such as a wrong label, a needless fix
pull request, or a merge before its CI ends.

**Needs:** The merged change, and one agent session that meets a real CI
failure.

**Done when:** One real failure was walked against the text, and the result
is in a commit message or in a new follow-up item.

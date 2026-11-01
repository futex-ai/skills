# No cycle step confirms the wake routine

- **Severity:** Low. **Effort:** Small. **Confidence:** High. **Harder later:** No.
- **Kind:** Fix after merge.
- **Added:** 2026-10-31, from branch `calummoore/conductor-workspace-coordinator-skill` (PR #37), a problem that the check of review round 6, finding 12, found.
- **Location:** `skills/conductor-section-workspace-coordinator/references/routine.md` (section "Ensure the routine", step 5), `skills/conductor-section-workspace-coordinator/SKILL.md` (section "Each cycle").
- **Reason:** The check that found it ran in the last review round of that branch, and the review rules allow no third fix round without the user.

- **Source:** Review.
- **Category:** docs or spec.
- **Terms:**
  - **Routine state:** the `Routine:` line of the coordinator's state file, such as `created on <date>, trigger waiting for the user` or `confirmed on <date>`.
- **Background:** Step 5 of `references/routine.md` says that a cycle that starts with a `[coordinator wake]` message proves that the routine runs, and sets `Routine: confirmed on <date>`. The coordinator reads `references/routine.md` only in its first cycle.
- **Problem:** No step of the cycle in `SKILL.md` leads to that rule. After the user adds the hourly trigger, the state can stay at "trigger waiting for the user", and the status report keeps asking the user for it.
- **Impact if no action:** The coordinator asks the user for a trigger that already exists.
- **Root question:** How does the coordinator learn that its wake routine runs?
- **Options:**
  - **A.** Add to "Each cycle" in `SKILL.md`: a cycle that starts with `[coordinator wake]` sets `Routine: confirmed on <date>`. Effort: Small.
- **Left out:** Fewer than three approaches are real: the wake message is the only sign of a run that reaches the coordinator without a user API key.
- **Wider fix:** None.
- **Previous examples:** None found.
- **Related:** `plans/follow-ups/coordinator-wake-routine-drift.md`: the same routine procedure.
- **Recommendation:** A. The wake message already proves the run.
- **Action:** fix after merge, apply A, because the review rounds of the branch that found it had ended.

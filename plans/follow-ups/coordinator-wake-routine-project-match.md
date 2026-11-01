# Routine check accepts another project's routine

- **Severity:** Medium. **Likelihood:** Common. **Effort:** Small. **Confidence:** High. **Harder later:** No.
- **Kind:** Fix after merge.
- **Added:** 2026-10-31, from branch `calummoore/conductor-workspace-coordinator-skill` (PR #37), a problem that the check of review round 6, finding 12, found.
- **Location:** `skills/conductor-section-workspace-coordinator/references/routine.md` (section "Ensure the routine", step 3).
- **Reason:** The check that found it ran in the last review round of that branch, and the review rules allow no third fix round without the user.

- **Source:** Review.
- **Category:** product bug.
- **Terms:**
  - **Wake routine:** a saved Conductor routine, named `coordinator wake`, that runs hourly and messages each idle section coordinator.
- **Background:** In its first cycle, the coordinator runs `conductor --json routine list` and looks for a routine named `coordinator wake` "for this project". One routine per project wakes every coordinator of that project.
- **Problem:** `routine list` returns the routines of every project of the user. Only a routine's `repoUrl` names its project, and the procedure does not say to compare it.
- **Impact if no action:** A coordinator can confirm the routine of another project, and its own project then has no routine that wakes it.
- **Root question:** How does the coordinator find the wake routine of its own project?
- **Options:**
  - **A.** In step 3, match the routine by its name and by a `repoUrl` equal to the `repoUrl` of `conductor --json workspace get`. Effort: Small.
- **Left out:** Fewer than three approaches are real: the routine object has no project field but `repoUrl`, and the name alone is the defect.
- **Wider fix:** None. The fix is a one-line rule in the procedure.
- **Previous examples:** None found.
- **Related:** `plans/follow-ups/coordinator-wake-routine-drift.md`: its options A and E also read `routine list`, so they need this match.
- **Recommendation:** A. It names the field that identifies the project.
- **Action:** fix after merge, apply A, because the review rounds of the branch that found it had ended.

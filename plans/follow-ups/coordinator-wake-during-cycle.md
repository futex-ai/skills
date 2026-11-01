# A wake can start a second coordinator cycle

- **Severity:** Medium. **Likelihood:** Common. **Effort:** Small. **Confidence:** Medium. **Harder later:** No.
- **Kind:** Fix after merge.
- **Added:** 2026-10-31, from branch `calummoore/conductor-workspace-coordinator-skill` (PR #37), a problem that the check of review round 6, finding 13, found.
- **Location:** `skills/conductor-section-workspace-coordinator/templates/routine-prompt.md`, `skills/conductor-section-workspace-coordinator/SKILL.md` (section "Each cycle", step 6).
- **Reason:** The check that found it ran in the last review round of that branch, and the review rules allow no third fix round without the user.

- **Source:** Review.
- **Category:** product bug.
- **Terms:**
  - **Wake routine:** a saved Conductor routine that runs hourly and sends `[coordinator wake] continue` to each coordinator whose session status is `idle`.
- **Background:** A coordinator cycle can wait for children with background tasks. Conductor shows a Claude session as `idle` after each turn, also while the agent waits on its background tasks inside the same cycle.
- **Problem:** The routine sees `idle` and sends the wake message. The message reaches the coordinator in the middle of its cycle, and the coordinator can start a second cycle inside the first.
- **Impact if no action:** Two cycles can act on the same child, for example send it the same message twice.
- **Root question:** How does a coordinator run one cycle at a time when a wake message arrives during a cycle?
- **Options:**
  - **A.** The coordinator writes `Cycle: running since <time>` in its state file at the start of a cycle, and clears it at the end. A wake message during a running cycle gets a one-line answer and no new cycle. Effort: Small.
  - **B.** The routine reads the coordinator's session with the reader of the coordinator skill, `scripts/last-report.sh`, and skips it while the result is `pending:` or `waiting:`. The routine workspace then needs the installed skill. Effort: Medium.
- **Left out:** A wake with a longer interval fails the goal: a cycle can still run at the time of a wake.
- **Wider fix:** A. It holds whatever wakes the coordinator, also a message of the user.
- **Previous examples:** None found.
- **Related:** `plans/follow-ups/coordinator-wake-routine-drift.md`: its option D moves the wake steps into a script, which could also apply B.
- **Recommendation:** A. It keeps one cycle at a time with a rule inside the skill and no new dependency.
- **Action:** fix after merge, apply A, because the review rounds of the branch that found it had ended.

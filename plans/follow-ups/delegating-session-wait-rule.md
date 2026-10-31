# Delegating waits for idle, which misses failures

- **Severity:** Medium (estimate). **Likelihood:** Common (estimate). **Effort:** Small (estimate). **Confidence:** High. **Harder later:** No.
- **Kind:** Outside the scope.
- **Added:** 2026-10-31, from branch `calummoore/conductor-workspace-coordinator-skill` (PR #37), problems outside the scope that the checks of review round 6, findings 11 and 13, found.
- **Location:** `skills/delegating/references/conductor.md` (section "Read, message, and archive").
- **Reason:** The file is on `main`, and that branch did not change it.

- **Source:** Review.
- **Category:** product bug.
- **Terms:**
  - **Agent SDK state:** the `state` of a `session_state_changed` event in a Claude transcript: `running`, `idle`, or `requires_action`.
- **Background:** The `delegating` skill tells an orchestrator to wait until `conductor session status` says `idle`, then to take the last text of the agent as its report. The coordinator skill solved the same problem in its `scripts/last-report.sh` on 2026-10-31.
- **Problem:**
  - `session status` can also say `error`. A failed turn usually shows `idle`, with its cause only in the status field `lastError`, and sometimes no event in the transcript.
  - Conductor shows a Claude session as `idle` after each turn, also while the agent goes on with the same request, for example after its background tasks end. The Agent SDK state stays `running` then.
  - So an orchestrator can take a failure as an empty report, or take progress text as the report of a helper.
- **Impact if no action:** Orchestrators act on wrong reports, and failed helpers go unnoticed.
- **Root question:** How does an agent know that a delegated session finished its request, and how it ended?
- **Options:**
  - **A.** Extend the rule in `conductor.md`: wait while the status is `working` or the last Agent SDK state is `running`. Treat status `error`, or a `lastError` after your message, as a failed turn. Effort: Small.
  - **B.** Move the reader of the coordinator skill into the `delegating` skill as a shared script, and point both skills to it. Effort: Medium.
- **Left out:** A request to Conductor to add the live task list to `session status` stays out for now: it is outside this repository. It would fix every reader at once.
- **Wider fix:** B. One reader keeps every agent on the same rule.
- **Previous examples:** The coordinator skill's reader, fixed on 2026-10-31 for the same causes.
- **Recommendation:** B. The coordinator's reader already handles these cases and has tests.
- **Action:** fix after merge, apply B, because the file is outside the scope of the branch that found the problem.

# Coordinator waits on a hung child forever

- **Severity:** High (estimate). **Likelihood:** Rare (estimate). **Effort:** Medium (estimate). **Confidence:** High. **Harder later:** No.
- **Kind:** Needs decision.
- **Added:** 2026-10-31, from branch `calummoore/conductor-workspace-coordinator-skill` (PR #37), a problem that the check of review round 6, finding 11, found.
- **Location:** `skills/conductor-section-workspace-coordinator/scripts/last-report.sh`, `skills/conductor-section-workspace-coordinator/references/cycle.md` (section "Read a report").
- **Reason:** A time limit for a working child adds behaviour that no requirement covers, and its length trades false alarms against long stalls.

- **Source:** Review.
- **Category:** product bug.
- **Terms:**
  - **Reader:** `scripts/last-report.sh` of the coordinator skill. It prints one line about a child's latest request, such as `pending: working`.
- **Background:**
  - The coordinator waits while the reader prints `pending:` or `waiting:`, and sends nothing then.
  - A Codex session that hits a usage limit stays `working`. Codex obeys the `retry-after` header of the model proxy. On 2026-10-28 that header was 383549 seconds, about 4.4 days, and the session showed no event in that time.
  - Another live Codex session showed 18 reconnect errors, then no event for about 22 hours, until its workspace shut down.
  - The reader treats a Claude turn as stopped after 30 minutes with no event. It has no such limit for a session whose status is `working`.
  - The `delegating` skill says to ask the user at once about a blocked model, with the retry time.
- **Problem:** A child that hangs at `working` keeps the coordinator waiting with no limit. The coordinator never cancels the turn, retries, or asks the user.
- **Impact if no action:** One hung child blocks its workspace until a person looks, which can take days in an unattended section.
- **Root question:** How does the coordinator notice that a working child has stopped making progress?
- **Options:**
  - **A.** Let the reader print `error: stalled` for a working session whose last event is an error with no event after it for 15 minutes. The coordinator cancels the turn with `conductor session cancel <id>` and applies its one retry. Effort: Medium.
  - **B.** Let the reader print the age of the last event with `pending: working`. The coordinator escalates when the age passes a limit that the state file holds. Effort: Small.
  - **C.** Add the same check to the wake routine, so that a hung coordinator is found too. Effort: Medium.
- **Left out:** A fixed limit for every working session fails the goal: a long gate run or implementation is a real wait, and it shows no error event.
- **Wider fix:** A. An error event followed by silence is the shape of both live hangs, and a normal long wait does not have it.
- **Previous examples:** The two live sessions above: a review session of this branch on 2026-10-28, and session `6f97d436` in another workspace.
- **Recommendation:** A. It catches the known hangs and keeps long real waits.
- **Action:** ask the user, because condition 2 holds: a time limit for a working child is new behaviour that no requirement covers.

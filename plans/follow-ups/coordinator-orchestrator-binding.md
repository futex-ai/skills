# Coordinator trusts the orchestrator session name

- **Severity:** Medium. **Likelihood:** Rare. **Effort:** Medium. **Confidence:** High. **Harder later:** No.
- **Kind:** Needs decision.
- **Added:** 2026-10-31, from branch `calummoore/conductor-workspace-coordinator-skill` (PR #37), review round 3, finding 2.
- **Location:** `skills/conductor-section-workspace-coordinator/scripts/section-workspaces.sh:31-50`, `skills/conductor-section-workspace-coordinator/references/cycle.md` (section "Give a workspace an orchestrator").
- **Reason:** Keeping, renaming, or replacing a session of the user has real trade-offs, so the user decides.

- **Source:** Review.
- **Category:** product bug.
- **Terms:**
  - **Coordinator:** the agent of the `conductor-section-workspace-coordinator` skill. It schedules the workspaces of one Conductor section and messages each workspace's orchestrator.
  - **Orchestrator:** the session of a child workspace that runs the `default orchestrator` action of the `models` skill, Claude `opus-5-5-1m` at max effort. The coordinator names it `orchestrator`.
  - **Binding:** recording the checked session id of a workspace's orchestrator on the coordinator's board.
- **Background:** `scripts/section-workspaces.sh` picks the last session named `orchestrator` of each child workspace, and falls back to the newest session. The coordinator sends every message for the workspace to that session. A workspace that the user added gets a model and effort check before the coordinator adopts its session. A workspace that the coordinator creates gets no check.
- **Problem:** The scan trusts the name alone. A session named `orchestrator` on another model or effort gets the messages. So does a later helper that takes the name. Four actions share Claude `opus-5-5-1m` at max effort: the orchestrator, the UI and docs implementors, and the second-pass review agent. So a model check alone cannot tell them apart.
- **Impact if no action:** A child's plan, answers, or merge messages can reach a helper session or a session on the wrong model.
- **Root question:** How does the coordinator know which session manages a workspace?
- **Options:**
  - **A.** Check the named session against the action at every scan. Rename a wrong session before you create its replacement. Effort: Medium.
  - **B.** Escalate to the user when the named session has another model or effort. Send no more messages until the user chooses. Effort: Small.
  - **C.** Archive the wrong session and create a replacement. This breaks the design call of 2026-10-28 that the coordinator never archives a session of the user. Effort: Small.
  - **D.** Bind the orchestrator by its session id. Check the model and the effort only at binding: at creation, at adoption, or when the bound session is gone. Compare with the action after the section's overrides. When a check fails, start a new orchestrator beside the old session, and leave the old session as it is. Pass the board's session ids to the scan, which then prefers a bound id over a name. Effort: Medium.
- **Left out:** Not recorded.
- **Wider fix:** D. It still routes correctly when a session with the right model takes the name.
- **Previous examples:** None found.
- **Recommendation:** D. Messages reach only a checked session, the user's sessions stay untouched, and no workspace stops to wait.
- **Action:** ask the user, because the options have real trade-offs and none is clearly best: keeping, renaming, or replacing the user's session.

# Workspaces outside Conductor conflict with models

- **Severity:** Medium. **Effort:** Small.
- **Kind:** Needs decision.
- **Added:** 2026-10-29, from PR #16, review rounds 14 and 15, finding 41.
- **Location:** `skills/parallel-agents/references/workspaces.md` lines 3-10.
- **Reason:** Each option that closes the finding changes a user decision
  or `models` on `main`, so it waits for the user.

### 41. Workspaces outside Conductor conflict with `models`

- **Severity:** Medium. **Effort:** Small.
- **Category:** Docs or spec.
- **Location:** `skills/parallel-agents/references/workspaces.md` lines 3-10.
- **Terms:**
  - **`models` skill:** the shared skill that maps each action to an
    agent, a model, an effort, and a route.
  - **Workspace reference:** the tool-free procedure for one work item on
    its own branch, at the location above.
- **Background:** The user asked for a general workspace file beside the
  Conductor file in `41bb908`, so that an agent on another tool has a
  procedure. The `models` skill, merged later in #39, gives work that
  becomes an implementation or a pull request its own Conductor
  workspace, with no exception. The reference says: in Conductor, each
  workspace is a Conductor workspace. Without Conductor, a worktree
  agent, a second machine, or a cloud session follows the same procedure.
- **Problem:** Outside Conductor, the reference allows routes that
  `models` does not list.
- **Impact if no action:** An agent outside Conductor can push a
  work-item branch and open a pull request without a Conductor workspace.
- **Options:**
  - **A.** Conductor only: remove the routes outside Conductor. This
    reverses the request of `41bb908`. Effort: Small.
  - **B.** Keep the routes, and add one sentence to `models` that allows
    them when Conductor is not available. This changes `models` on
    `main`. Effort: Small.
  - **C.** Keep the current text, and accept the difference from
    `models`. Effort: Small.
  - **D.** Keep the tool-free wording, and take workspace selection from
    `models` with no exception. In practice it is A, but the route rule
    stays in `models` only. Effort: Small.
  - **E.** Keep the general procedure, and take the route of each work
    item from `models` only. When that route cannot run after one retry,
    ask the user for the route of the task, with the error text. The
    procedure then runs on the route that the user names, for that task
    only. Effort: Small.
- **Wider fix:** None. The `documentation` rule that each fact lives in
  one place is in force. D and E follow it.
- **Previous examples:** Round 12, finding 39. Round 8, finding 30.
- **Recommendation:** E. It closes the finding without a change to
  `models`, and it keeps the general procedure for a route that the user
  names for one task. The first pass recommended D.
- **Action:** ask the user, because A and D reverse the request of
  `41bb908`, and B changes `models` on `main`.

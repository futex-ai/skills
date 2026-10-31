# Review prompts lack the six prompt fields

- **Severity:** Low (estimate). **Effort:** Small (estimate). **Confidence:** Medium. **Harder later:** No.
- **Kind:** Outside the scope.
- **Added:** 2026-10-31, from branch `calummoore/conductor-workspace-coordinator-skill` (PR #37), a problem outside the scope that the check of review round 5, finding 9, found.
- **Location:** `skills/implementation-review/references/review-prompt.md`, `skills/implementation-review/references/check-prompt.md`, `skills/implementation-review/references/second-pass-prompt.md`.
- **Reason:** These files are on `main`, and that branch did not change them.

- **Source:** Review.
- **Category:** repository rule.
- **Terms:**
  - **Six prompt fields:** Scope, Goal, Context, Steps, Constraints, and Output. The `delegating` skill requires them in each prompt that starts a subagent, a session, or a workspace.
- **Background:** The `implementation-review` skill gives fixed prompts to the reviewer, to each finding check, and to the options check. An agent pastes each prompt into a fresh session or subagent.
- **Problem:** None of the three prompts uses the six fields, and no skill exempts a fixed prompt from the rule.
- **Impact if no action:** The review prompts break a rule of the `delegating` skill. A reader cannot find the scope, the constraints, or the expected output in a fixed place.
- **Root question:** Do fixed review prompts follow the prompt format of the `delegating` skill?
- **Options:**
  - **A.** Put the text of each prompt under the six fields. Keep every instruction. Effort: Small.
  - **B.** Add one sentence to the `delegating` skill that exempts a fixed prompt of another skill. Effort: Small.
- **Left out:** A test of the prompt text stays out: the `testing` skill keeps skill text out of tests.
- **Wider fix:** None. The rule in `delegating` already covers the class.
- **Previous examples:** The coordinator's wake routine prompt, moved to the six fields on 2026-10-31.
- **Recommendation:** A. It applies the rule in force without a new exception.
- **Action:** fix after merge, apply A, because the prompts are outside the scope of the branch that found them.

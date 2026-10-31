# <The problem, in eight words or fewer>

- **Severity:** <High, Medium, or Low>. **Likelihood:** <Common or Rare, for a product bug only.> **Effort:** <Small, Medium, or Large.> **Confidence:** <High, Medium, or Low.> **Harder later:** <Yes or No.>
- **Kind:** <Fix after merge, Needs decision, Outside the scope, or Post-merge task.>
- **Added:** <YYYY-MM-DD>, from <the branch or the pull request, and the review finding number when there is one.>
- **Location:** <Each file path and line, or "None" when the work has no place in the code. Do not point to the body.>
- **Reason:** <One sentence: the fact about this work that makes it wait until after the merge. Do not only repeat the kind.>

<The body. It holds every fact that the work needs. A reader with only the
repository and this file can understand it, decide, and do the work. Do
not depend on a plan, a review report, a findings file, `.context/`, a
pull request, or a link. Read "Writing an item" in
`references/follow-up-items.md` of the `plans` skill. The body depends on
the kind:

- Every kind except a post-merge task: the item layout of the
  `decisions-and-findings` skill, from **Terms** to **Action**. Write each
  field. A wider fix also gives the problem of each finding that it
  covers. A blocked wider fix has the kind Needs decision. A wider fix
  that the agent split off has the kind Fix after merge.
- A post-merge task: **Terms** when the task needs them, then
  **Background**, **Task**, **Impact if no action**, **Needs**, and
  **Done when**. **Needs** gives what the task needs, such as the
  deployed change or credentials, or "Nothing". **Done when** gives the
  result that shows that the task is complete.>

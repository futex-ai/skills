# Skill template frontmatter is invalid YAML

- **Severity:** Low. **Effort:** Small. **Confidence:** High. **Harder later:** No.
- **Kind:** Outside the scope.
- **Added:** 2026-10-31, from branch `calummoore/conductor-workspace-coordinator-skill` (PR #37), a problem outside the scope that the check of review round 6, finding 10, found.
- **Location:** `skills/writing-skills/templates/SKILL.md:3`.
- **Reason:** The template is on `main`, and that branch did not change it.

- **Source:** Review.
- **Category:** repository rule.
- **Terms:**
  - **Skill template:** `skills/writing-skills/templates/SKILL.md`, the file that a new skill starts from.
- **Background:** The `writing-skills` skill tells an author to copy the template. Its line 3 is `description: Use when <the moments and the symptoms: what the agent sees, is asked, or is about to do. Triggers only, no summary of the content>.`, a plain YAML value that holds `symptoms: what`.
- **Problem:** A plain YAML value cannot hold `: `, so strictyaml rejects the template frontmatter at line 3, column 52.
- **Impact if no action:** A new skill copied from the template starts with invalid frontmatter.
- **Root question:** How does the skill template give a valid start?
- **Options:**
  - **A.** Put the placeholder description in double quotes. Effort: Small.
  - **B.** Write the placeholder as a folded block, `description: >-`, with the text on the next line. Effort: Small.
- **Left out:** Deleting the template fails the goal: authors start from it.
- **Wider fix:** The YAML check in `plans/follow-ups/skill-frontmatter-yaml-check.md` covers this class.
- **Previous examples:** The coordinator skill description, fixed on 2026-10-31 with double quotes.
- **Related:** `plans/follow-ups/skill-frontmatter-yaml-check.md`: the same class of defect. `plans/follow-ups/writing-skills-template-listed-as-skill.md`: the same file.
- **Recommendation:** A. It matches the fix of the coordinator description, and `scripts/check.sh` reads the line as it is.
- **Action:** fix after merge, apply A, because the template is outside the scope of the branch that found it.

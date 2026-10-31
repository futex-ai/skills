# Skill template frontmatter is invalid YAML

- **Severity:** Low (estimate). **Effort:** Small (estimate). **Confidence:** High. **Harder later:** No.
- **Kind:** Outside the scope.
- **Added:** 2026-10-31, from branch `calummoore/conductor-workspace-coordinator-skill` (PR #37), a problem outside the scope that the check of review round 6, finding 10, found.
- **Location:** `skills/writing-skills/templates/SKILL.md:3`.
- **Reason:** The template is on `main`, and that branch did not change it.

- **Source:** Review.
- **Category:** repository rule.
- **Terms:**
  - **Skill template:** `skills/writing-skills/templates/SKILL.md`, the file that a new skill starts from.
- **Background:** The `writing-skills` skill tells an author to copy the template. Its line 3 is `description: Use when <the moments and the symptoms: what the agent sees, is asked, or is about to do. Triggers only, no summary of the content>.`, a plain YAML value that holds `symptoms: what`.
- **Problem:**
  - strictyaml rejects the template frontmatter at line 3, column 52, because a plain YAML value cannot hold `: `.
  - Where `writing-skills` is linked, Codex 0.164.0 scans nested folders and lists the template as a skill named `<directory-name>`.
- **Impact if no action:** A new skill copied from the template starts with invalid frontmatter. Codex users see a stray skill in their list.
- **Root question:** How does the skill template give a valid start without showing up as a skill?
- **Options:**
  - **A.** Quote the placeholder description, so that the template parses. Effort: Small.
  - **B.** Apply A, and rename the template file, for example to `SKILL.template.md`, so that no agent loads it as a skill. Update each link to it. Effort: Small.
- **Left out:** Deleting the template fails the goal: authors start from it.
- **Wider fix:** The YAML check in `plans/follow-ups/skill-frontmatter-yaml-check.md` covers the parse part of this class.
- **Previous examples:** The coordinator skill description, fixed on 2026-10-31.
- **Related:** `plans/follow-ups/skill-frontmatter-yaml-check.md`: the same class of defect. That check would catch the template once it reads the templates too.
- **Recommendation:** B. It fixes both problems in one small change.
- **Action:** fix after merge, apply B, because the template is outside the scope of the branch that found it.

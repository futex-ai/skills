# Codex lists the skill template as a skill

- **Severity:** Low. **Effort:** Small. **Confidence:** High. **Harder later:** No.
- **Kind:** Outside the scope.
- **Added:** 2026-10-31, from branch `calummoore/conductor-workspace-coordinator-skill` (PR #37), a problem outside the scope that the check of review round 6, finding 10, found.
- **Location:** `skills/writing-skills/templates/SKILL.md`.
- **Reason:** The template is on `main`, and that branch did not change it.

- **Source:** Review.
- **Category:** repository rule.
- **Terms:**
  - **Skill template:** `skills/writing-skills/templates/SKILL.md`, the file that a new skill starts from. Its `name` is the placeholder `<directory-name>`.
- **Background:** `scripts/install.sh` links the `writing-skills` skill only with `--opt-in`. Codex 0.164.0 scans the nested folders of a linked skill for files named `SKILL.md`.
- **Problem:** Where `writing-skills` is linked, Codex lists the template as a skill named `<directory-name>`.
- **Impact if no action:** Codex users see a stray skill in their list, and an agent can load the template as a skill.
- **Root question:** How does the skill template stay out of an agent's skill list?
- **Options:**
  - **A.** Rename the template, for example to `SKILL.template.md`, and update each link to it. Effort: Small.
  - **B.** Move the template outside the skill directory, for example under `docs/`. Update each link. Effort: Small.
- **Left out:** Deleting the template fails the goal: authors start from it.
- **Wider fix:** None.
- **Previous examples:** None found.
- **Related:** `plans/follow-ups/writing-skills-template-frontmatter.md`: the same file.
- **Recommendation:** A. A file that is not named `SKILL.md` is not a skill to any agent, and it stays beside the skill that uses it.
- **Action:** fix after merge, apply A, because the template is outside the scope of the branch that found it.

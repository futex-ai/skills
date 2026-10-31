# Skill check does not parse frontmatter as YAML

- **Severity:** High. **Likelihood:** Rare. **Effort:** Small (estimate). **Confidence:** High. **Harder later:** No.
- **Kind:** Needs decision.
- **Added:** 2026-10-31, from branch `calummoore/conductor-workspace-coordinator-skill` (PR #37), review round 6, the blocked wider fix of finding 10.
- **Location:** `scripts/check.sh` (the frontmatter loop), `skills/writing-skills/templates/SKILL.md:3`.
- **Reason:** Every option adds a check that rejects a skill, and the always-on rules leave a new gate to the user.

- **Source:** Review.
- **Category:** repository rule.
- **Terms:**
  - **Frontmatter:** the YAML block between the first two `---` lines of a `SKILL.md`. Agents read its `name` and `description` before they load the skill.
  - **Plain scalar:** a YAML value without quotes. It cannot hold `: ` or ` #`.
- **Background:** The Agent Skills format requires YAML frontmatter. `scripts/check.sh` reads `name:` and `description:` with line filters and does not parse YAML. Claude Code 2.1.310 and Codex 0.164.0 load a description that holds `: ` anyway. strictyaml, js-yaml, yaml, gray-matter, and the GitHub file view reject it.
- **Problem:** Two cases of the class are known. The coordinator skill's description held `coordinator: <section>` as a plain scalar. A double-quoted value fixed it on 2026-10-31. The template that starts each new skill, `skills/writing-skills/templates/SKILL.md`, holds the placeholder `symptoms: what` in a plain scalar, so strictyaml rejects it at line 3, column 52. No check catches the class.
- **Impact if no action:** A new skill can ship frontmatter that strict readers cannot load. GitHub shows "Error in user YAML" on its file.
- **Root question:** How does every skill keep frontmatter that every reader of the Agent Skills format can parse?
- **Options:**
  - **A.** Parse each `SKILL.md` frontmatter, and the skill templates, as YAML in `scripts/check.sh`. It needs a parser dependency. Effort: Large.
  - **B.** Add a pattern check to `scripts/check.sh`. It fails when an unquoted `name:` or `description:` value holds `: ` or ` #`, or starts with a YAML indicator character. It needs no dependency. It misses other YAML errors, such as an open quote. Effort: Small.
  - **C.** Write the template description as a folded block, `description: >-`, and teach the `description:` filter of `scripts/check.sh` to join the indented lines. It protects new skills only. Effort: Small.
  - **D.** Run `skills-ref validate`, the validator that the Agent Skills specification names, in `.github/workflows/check.yml`. It needs Python 3.11 or later and runs in CI only. Effort: Large.
- **Left out:** A quoting rule in the text of `writing-skills` stays out: that skill says that a rule which a script can enforce belongs in a check.
- **Wider fix:** A. It catches every YAML error. B is the Small fallback when the user accepts a gate but not a dependency.
- **Previous examples:** The coordinator skill description, fixed on 2026-10-31. The `writing-skills` template on `main`, since commit `8dfc7be`.
- **Recommendation:** B. It catches both known cases with no new dependency, at Small effort.
- **Action:** ask the user, because condition 3 holds: every option adds a gate.

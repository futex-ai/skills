---
name: writing-skills
description: Use when you create a skill, edit a SKILL.md, write or change a skill description, add a reference, template, or script to a skill, or when an agent skipped a rule, did not load a skill, or loaded the wrong one. Covers the trigger-style description, the SKILL.md layout and size limits, the baseline, pressure test, and micro-test, the form that fixes each kind of failure, excuse tables built from recorded excuses, and the repository steps for a new or changed skill.
---

# Writing skills

A skill is a procedure that an agent loads at one moment. The always-on
rules are short because every line costs context on every turn. A skill
holds the detail and costs context only when its moment comes.

Write a skill for a rule that an agent needs at a moment and that no
check can enforce. The rule must be too long for the always-on rules. A
command, path, or cap of one repository belongs in that repository's
`AGENTS.md`. A rule that a script can enforce belongs in a check. A new
check needs the user's approval.

Writing a skill is test-driven. The test is a scenario that an agent runs
without the skill. The failure that you record says what the skill must
say, and in which form. A skill written without a baseline teaches what
you imagined, not what the agent does.

## Kinds of skill

- **Discipline**: a rule that the agent knows and is tempted to skip, for
  example the complete gate or the deletion audit. Test it under pressure.
- **Procedure**: steps and a layout that give an output of a fixed shape,
  for example a commit message or a final report. Test the shape.
- **Reference**: facts to look up, for example the sections of a crate
  README. Test that the agent finds the fact and applies it.

## The description

An agent sees only the description before the moment. The description
decides whether the agent loads the skill.

- Start with `Use when`, `Use before`, or `Use after`. Then list the
  moments and the symptoms as keywords: what the agent sees, is asked, or
  is about to do. Name file types, commands, error texts, and the words a
  user would type.
- Then write `Covers` and the topic nouns, so that an agent can tell two
  skills apart. Do not list the steps of the procedure in their order. An
  agent reads an ordered list as the procedure and skips the file.
- Do not write in the first person. Address the agent as you. Do not
  describe the skill's own method.
- Stay under 1024 characters. The repository check, `check.sh` under
  `scripts/`, fails above that.
- An existing description that starts with a noun phrase moves to this
  form when the skill is next edited. Check that the agent still loads
  it, as [references/testing.md](references/testing.md) describes.

Example: "Use when a test fails and then passes on a rerun, when a test
would assert elapsed time, timeouts, or performance, or when you choose
between a real and a fake clock. Covers operation counts, captured inputs,
event order, fake clocks, and the flaky-test procedure."

## The SKILL.md file

- `name` matches the directory: lowercase letters, digits, single hyphens.
- Order the content by the moment the agent needs each part, in the order
  of the work. [templates/SKILL.md](templates/SKILL.md) is the skeleton.
- Target 150 lines. The repository check warns at 200 and fails at 500.
  Put a long contract, a prompt, or a set of examples under `references/`.
  Put a skeleton under `templates/` and an executable script under
  `scripts/`. Link each file by its relative path. The check confirms that
  it exists.
- Write in Simplified Technical English, as the always-on rules say.
- Name another skill in backticks, as in "the `git-commit` skill". Do not
  use an `@` link. It loads the file at once, before the moment.
- Give no repository-specific paths, commands, or crate names. Say "the
  gate named in `AGENTS.md`".
- Give one real example, not three invented ones. Do not tell the story
  of how you once solved the problem.
- End a procedure skill with a checklist.

## The form that fixes each failure

Match the form of the text to the failure that the baseline shows.
[references/forms.md](references/forms.md) gives an example of each form.

| The baseline shows | Write |
| --- | --- |
| The agent knows the rule and skips it under pressure | A prohibition, a table of excuses with answers, and a red-flag list |
| The output has the wrong shape | A recipe with the steps, and a template with labels |
| The agent leaves out one element | A required slot with a label in the layout |
| The agent applies the rule in the wrong case | A condition with a plain predicate: when X, do Y |
| The agent does not load the skill | Symptom keywords in the description |

- An exception clause widens a rule. An agent reads "unless it is clearly
  safe" as permission. Write the predicate instead.
- A workaround that keeps the words of a rule and loses its purpose breaks
  the rule. Say so in a discipline skill.
- Build an excuse table only from excuses that an agent really gave. Take
  them verbatim from a baseline, a pressure test, or a real session. An
  imagined excuse misses the real one. Each row gives the excuse and the
  answer.

## Test the skill

[references/testing.md](references/testing.md) gives the method: the
baseline, the pressure test, the micro-test, and how to read a run. The
runs are manual. They cost money and are not deterministic, so they are
not in CI.

1. Write the scenario: a prompt with the pressures that fit the kind of
   skill, and a small workspace.
2. Baseline: run the scenario without the skill. Record what the agent
   did and each excuse verbatim under `.context/`.
3. Write the smallest text that answers the recorded failures, in the form
   from the table above.
4. Pressure test: run the scenario with the skill text. The agent must
   follow the rule under three or more combined pressures.
5. Add a counter for each new excuse that the pressure test shows. Rerun.

A discipline skill needs steps 2 and 4. A procedure or reference skill
needs only a check of the output shape or the fact. An edit of an
existing skill follows the same loop, with the old text as the baseline.
Put the counts in the pull request, not the transcripts.

## Repository steps

1. Create `skills/<name>/SKILL.md` and the files that it links.
2. Add the row to the skills table in the repository `README.md`.
3. Run the repository check, `shellcheck` on new scripts, and
   `tests/run.sh`.
4. Add the skill to the `agents-md` template when product repositories
   need it at a named moment.
5. Say in the pull request that an existing install gets the skill when
   `update.sh` or `install.sh` under `scripts/` runs there.

## Checklist

- [ ] The description starts with `Use when`, `Use before`, or `Use
      after`. It has symptom keywords and topic nouns. It lists no steps.
- [ ] For a discipline skill, the baseline is recorded under `.context/`
      before the text.
- [ ] The form of the text matches the recorded failure.
- [ ] Every excuse table row comes from a recorded excuse.
- [ ] For a discipline skill, the pressure test passed. The counts are in
      the pull request.
- [ ] `SKILL.md` is near 150 lines. Detail is under `references/`.
- [ ] The README row exists. The repository check and `tests/run.sh` pass.

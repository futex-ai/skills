---
name: writing-skills
description: Use when you create or edit a skill, write or change a skill description, or when an agent skipped a rule, did not load a skill, or loaded the wrong one. Covers trigger descriptions, the SKILL.md layout, the form for each failure, excuse tables, and real-session evidence.
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

A skill answers a failure that an agent really had. The failure says what
the skill must say, and in which form. Real sessions are the evidence. A
staged scenario in a toy repository shows the prompt, not the agent. A
skill written from an imagined failure answers the wrong one.

## Kinds of skill

- **Discipline**: a rule that the agent knows and is tempted to skip, for
  example the complete gate or the deletion audit. The evidence is a
  session where the agent skipped it.
- **Procedure**: steps and a layout that give an output of a fixed shape,
  for example a commit message or a final report. The evidence is an
  output with the wrong shape.
- **Reference**: facts to look up, for example the sections of a crate
  README. The evidence is a session where the agent guessed the fact.

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
- Target 300 characters. Keep under 500. Every description loads into
  every session on every turn, so each character has a cost. Put at most
  seven nouns after `Covers`. The repository check, `check.sh` under
  `scripts/`, warns above 500 characters and fails above 1024.
- An existing description that starts with a noun phrase moves to this
  form when the skill is next edited. Then watch the next real session
  that reaches the moment, and confirm that it loads the skill.

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

Match the form of the text to the failure that the session shows.
[references/forms.md](references/forms.md) gives an example of each form.

| The session shows | Write |
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
- Build an excuse table only from excuses that an agent really gave in a
  real session. Copy them verbatim. An imagined excuse misses the real
  one. Each row gives the excuse and the answer.

## Learn from real sessions

The evidence for a skill comes from real work in a real repository. A
staged test does not give it. The pressure in a real session is implicit:
a long task, a late hour, a gate that really takes twenty minutes. A
staged prompt announces the pressure, and the agent answers the prompt.

- Watch for a failure in real work: a skipped rule, a wrong shape, or a
  guessed fact. Copy the agent's words from the transcript into a notes
  file under `.context/`. Record the repository, the moment, and the
  words verbatim.
- Write the smallest text that answers the recorded failures, in the form
  from the table above.
- After the change, watch the next real sessions that reach the moment.
  Record whether the agent loaded the skill and followed the rule. Add a
  counter for each new excuse that you see.
- Keep the notes file. It is the record of why each row and each rule
  exists. It is not committed.

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
      It is near 300 characters and under 500.
- [ ] The failure that the skill answers is recorded under `.context/`
      from a real session, before the text.
- [ ] The form of the text matches the recorded failure.
- [ ] Every excuse table row quotes a real session.
- [ ] A real session that reached the moment loaded the skill.
- [ ] `SKILL.md` is near 150 lines. Detail is under `references/`.
- [ ] The README row exists. The repository check and `tests/run.sh` pass.

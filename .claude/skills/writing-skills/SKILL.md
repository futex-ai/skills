---
name: writing-skills
description: Use when you create or edit a skill, write or change a skill description, or when an agent skipped a rule, did not load a skill, or loaded the wrong one.
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

A skill answers failures that really happened. The failure says what the
skill must say, and in which form. A real repository holds the evidence
in its commits, pull requests, plans, and review reports. A staged
scenario in a toy repository shows the prompt, not the agent. A skill
written from an imagined failure answers the wrong one.

## Kinds of skill

- **Discipline**: a rule that the agent knows and is tempted to skip, for
  example the complete gate or the deletion audit. The evidence is a
  commit or a pull request where the rule was skipped.
- **Procedure**: steps and a layout that give an output of a fixed shape,
  for example a commit message or a final report. The evidence is a past
  output with the wrong shape.
- **Reference**: facts to look up, for example the sections of a crate
  README. The evidence is a place where the fact was guessed wrong.

## The description

An agent sees only the description before the moment. The description
decides whether the agent loads the skill.

- Start with `Use when`, `Use before`, or `Use after`. Then list the
  moments and the symptoms as keywords: what the agent sees, is asked, or
  is about to do. Name file types, commands, error texts, and the words a
  user would type.
- Write triggers only. Do not summarise the content, and do not list
  the steps of the procedure. An agent reads a summary as the skill and
  skips the file.
- When two skills share a moment, both load. That is correct. Make a
  trigger more specific only when the skill must not load at a moment.
- Do not write in the first person. Address the agent as you. Do not
  describe the skill's own method.
- Target 300 characters. Keep under 500. Every description loads into
  every session on every turn, so each character has a cost. The
  repository check, `check.sh` under `scripts/`, warns above 500
  characters and fails above 1024.
- An existing description can start with a noun phrase or end with a
  `Covers` summary. It moves to this form when the skill is next edited.

Example: "Use when a test fails and then passes on a rerun, when a test
would assert elapsed time, timeouts, or performance, or when you choose
between a real and a fake clock."

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

Match the form of the text to the failure that the cases show.
[references/forms.md](references/forms.md) gives an example of each form.

| The cases show | Write |
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
- Build an excuse table only from excuses that were really given. Copy
  them verbatim from the repository's record: a commit body, a pull
  request description, a review report, or a plan. An imagined excuse
  misses the real one. Each row gives the excuse and the answer.

## Check the skill against a repository

Ask the user for a real repository before you write the text, together
with your other questions. A skill that applies to every repository still
needs one to check against.

1. Find the past cases of the moment in that repository. Read the
   commits, the pull requests, the plans, the review reports under
   `.context/`, and the docs. For a commit rule, read the last twenty
   commit messages. For a deletion rule, list the deletions in the
   history. For a review rule, read the saved review reports.
2. Record each case under `.context/`: where it is, what the agent did,
   and its words verbatim when the record has them.
3. Write the smallest text that answers the recorded cases, in the form
   from the table above.
4. Walk each case again with the text. Ask whether the text, read at that
   moment, gives the instruction that changes the outcome. Fix the text
   until it does for every case.

## Repository steps

1. Create `skills/<name>/SKILL.md` and the files that it links. A skill
   for work in the skills repository only goes under `.claude/skills/`
   instead, with a link under `.agents/skills/`, and is not installed.
2. Add the row to the skills table in the repository `README.md`.
3. Run the repository check, `shellcheck` on new scripts, and
   `tests/run.sh`.
4. Add the skill to the `agents-md` template when product repositories
   need it at a named moment.
5. Say in the pull request that an existing install gets the skill when
   `update.sh` or `install.sh` under `scripts/` runs there.

## Checklist

- [ ] The description starts with `Use when`, `Use before`, or `Use
      after`. It has symptom keywords. It does not summarise the content.
      It is near 300 characters and under 500.
- [ ] The repository is named. Its past cases are recorded under
      `.context/` before the text.
- [ ] The form of the text matches the recorded cases.
- [ ] Every excuse table row quotes a recorded case.
- [ ] Every recorded case was walked through with the final text.
- [ ] `SKILL.md` is near 150 lines. Detail is under `references/`.
- [ ] The README row exists. The repository check and `tests/run.sh` pass.

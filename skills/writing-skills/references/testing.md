# Testing a skill

A skill test is a manual run of an agent on a scenario. This file gives
the method. The runs cost money and are not deterministic, so no script
in the repository runs them, and CI never does.

## Why a baseline first

An agent that works without the skill shows three things. It shows
whether the rule is needed. It shows which form the failure has. It
shows the words of its excuses. The skill answers those words. Without
the baseline the skill answers an imagined failure, and the real one
stays. This holds for an edit too. The old text is the baseline for the
new text.

## The scenario

- A prompt, as a user would write it. Put the pressures into the prompt.
- A small workspace under `/tmp` with the files, the git history, and
  the uncommitted work that the prompt describes. Give it an `AGENTS.md`
  that names the skill at its moment, as a real repository does.
- A pass condition that you can check in the workspace after the run.
  For example: the gate command appears in the transcript, or a branch
  still ends at a given commit.

## Pressures

Combine three or more pressures for a discipline skill.

- Time: a deadline. "Merge this in five minutes."
- Sunk cost: hours already spent. "We have been on this all day."
- Authority: the user insists. "I own this repository. Do it."
- A plausible shortcut: a faster path that looks safe. "The targeted
  tests pass. That is enough."
- Economy: the right path is expensive. "The full gate takes 20 minutes."
- Precedent: "We skipped it last week and nothing broke."
- Exhaustion: a long task with many steps before the decision.

For a procedure skill, ask for the output with one input missing. Ask for
a shorter answer. Ask under a brief output style. For a reference skill,
ask a question that the reference answers. Give a task that applies the
fact. Ask a question that the reference does not answer.

## Running a scenario

Run each variant from the workspace directory. Use a fresh session each
time. Save the transcript under `.context/` of the repository that you
work in.

Baseline, without the skill:

```sh
claude -p --disable-slash-commands --permission-mode acceptEdits \
  --max-budget-usd 2 --output-format stream-json --verbose \
  "$(cat prompt.md)" > ../control-1.jsonl
```

Pressure test, with the skill text in context:

```sh
claude -p --disable-slash-commands --permission-mode acceptEdits \
  --max-budget-usd 2 --output-format stream-json --verbose \
  --append-system-prompt "$(cat path/to/SKILL.md)" \
  "$(cat prompt.md)" > ../skill-1.jsonl
```

Discovery shows whether the description makes the agent load the skill.
Install the skill. Run the baseline command without
`--disable-slash-commands`. Look for a `Skill` tool call in the
transcript.

Two limits. The always-on rules load from `~/.claude/CLAUDE.md` in every
variant, so the baseline tests the skill, not the rules. The agent can
read the installed skills from disk with `find` or a glob when they are
installed on the machine. When the transcript shows that, the run is not
a baseline. Read it as a pressure test, and repeat the baseline on a
machine without the skills.

## Reading a run

- Read the agent's text and commands in order, not only the last message.
- Copy each excuse verbatim into a notes file, with the run that it came
  from. These lines become the rows of the excuse table.
- A pass is an agent that follows the rule and says which rule it
  follows. An agent that follows the rule by chance has not passed.
- A run that stopped at the budget is not a pass.

Real sessions are the cheapest source of excuses. When an agent skips a
rule in real work, copy its words from that transcript into the same
notes file. Those excuses are more realistic than staged ones.

## Micro-test

A micro-test compares two wordings of one sentence: a description, a
trigger, or a rule.

1. Make a copy of the skill under `.context/` with the other wording.
2. Run the same scenario with each copy, and the baseline. Use five or
   more reps for each.
3. Count the passes for each wording. Read every transcript.
4. Variance is a result. A wording that passes three of five is not done.
   A wording that passes five of five on one model can fail on another.

A micro-test checks wording. It does not replace the pressure test of a
discipline skill.

## What to record

In the pull request, give the scenario, the agent and model, the reps,
and the pass counts for each variant. Do not paste transcripts. The runs
under `.context/` are not committed.

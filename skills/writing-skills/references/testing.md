# Testing a skill

The behavior runner drives `claude -p` and `codex exec` with scenario
files and records every run under `.context/behavior/`. This file gives
the method. `tests/behavior/README.md` in the skills repository gives the
file layout and every option of the runner.

## Why a baseline first

An agent that works without the skill shows three things: whether the
rule is needed, which form the failure has, and the words of its excuses.
The skill answers those words. Without the baseline the skill answers an
imagined failure, and the real one stays. This holds for an edit too: the
old text is the baseline for the new text.

## Variants

- **control**: the agent gets the scenario, the always-on rules, and no
  skill. This is the baseline.
- **skill**: the agent gets the scenario, the always-on rules, and the
  skill text under test, appended to the rules file. This is the pressure
  test. It shows compliance when the text is in context.
- **discovery**: the agent gets the scenario, the always-on rules, and the
  skill installed as a skill. It shows whether the description makes the
  agent load the skill.

The runner gives each run a fresh temporary home. It copies only the
authentication, the settings without hooks, and the always-on rules into
that home. Installed skills stay out. An agent can still find the skill
on disk, for example with `find /`, when the machine has the skills
installed. The summary marks such a control run as `leak`. A leaked run
is not a baseline. It shows what the agent did with the text in hand, so
read it as a pressure test. Repeat the baseline, or run it on a machine
without the skills.

## Pressures

Put the pressure into the prompt and the workspace, not into the system
prompt. Combine three or more pressures for a discipline skill.

- Time: a deadline. "Merge this in five minutes."
- Sunk cost: hours already spent. "We have been on this all day."
- Authority: the user insists. "I own this repository. Do it."
- A plausible shortcut: a faster path that looks safe. "The targeted
  tests pass. That is enough."
- Economy: the right path is expensive. "The full gate takes 20 minutes."
- Precedent: "We skipped it last week and nothing broke."
- Exhaustion: a long task with many steps done before the decision.

For a procedure skill, ask for the output with one input missing, ask for
a shorter answer, or ask under a brief output style. For a reference
skill, ask a question that the reference answers, give a task that applies
the fact, and ask a question that the reference does not answer.

## Reading a run

Each run directory has `prompt.md`, `command.txt`, `transcript.jsonl`,
`actions.md` with the agent's own text and commands in order, `final.md`
with the last message, and the `workspace/` as the agent left it.

- Read every `actions.md`. The `Hint` column of `summary.md` comes from
  the scenario's `check.sh` on the workspace state, or from regular
  expressions over `actions.md`. It is not a verdict.
- Copy each excuse verbatim into `notes.md` beside `summary.md`, with the
  run that it came from. These lines become the rows of the excuse table.
- A pass is an agent that follows the rule and says which rule it follows.
  An agent that follows the rule by chance has not passed.
- A run that stopped at the timeout or at the budget is not a pass.

## Micro-test

A micro-test compares two wordings of one sentence: a description, a
trigger, or a rule.

1. Make a copy of the skill under `.context/` with the other wording.
2. Run the same scenario with `--skill-dir` for each copy, and the
   control. Use `--reps 5` or more. Use `--label` to name each run.
3. Count the passes for each wording. Read every transcript that the hint
   flagged, and some that it did not.
4. Variance is a result. A wording that passes three of five is not done.
   A wording that passes five of five on one model can fail on another.
   Run both agents when both are available.

A micro-test checks wording. It does not replace the pressure test of a
discipline skill.

## What to record

In the pull request, give the scenario names, the agents and models, the
reps, and the pass counts for each variant. Do not paste transcripts. The
runs under `.context/` are not committed.

# Behavior runner

`run.sh` drives `claude -p` and `codex exec` with scenario files and
records every run under `.context/behavior/`. It shows what an agent does
with and without a skill. The `writing-skills` skill gives the method:
baseline first, then the pressure test, then the micro-test.

The runs are slow, cost money, and are not deterministic. Nothing in CI
calls this script. `tests/behavior_test.sh` tests the runner itself with
fake agents and runs in CI.

## Requirements

- `claude` or `codex` on `PATH`, logged in. The runner copies the
  authentication of each agent into a temporary home.
- `jq`. `timeout` or `gtimeout` when a run must have a limit.
- The agent runs commands with the rights of the user, inside a scratch
  workspace. Run only scenarios that you trust.

## Usage

```sh
tests/behavior/run.sh --list
tests/behavior/run.sh --agent claude --variant control complete-gate
tests/behavior/run.sh --variant skill --reps 5 --label v2 flaky-no-sleep
tests/behavior/run.sh --skill-dir .context/drafts/finish-work complete-gate
tests/behavior/run.sh --dry-run
```

Options: `--agent`, `--variant`, `--reps`, `--skill-dir`,
`--scenarios-dir`, `--label`, `--out`, `--timeout`, `--budget`, `--model`,
`--dry-run`, `--list`. `run.sh --help` describes each one. Without
scenario names it runs every scenario. Without `--agent` it runs each
agent that is on `PATH`.

## Variants

- `control`: no skill. The baseline.
- `skill`: the skill text appended to the always-on rules file of the
  temporary home. The pressure test.
- `discovery`: the skill linked into the skills directory of the
  temporary home. Shows whether the description makes the agent load it.

Each run gets a fresh temporary home with copies of the authentication,
the settings without hooks, and the always-on rules. Installed skills stay
out. For `claude` the control and skill variants also pass
`--disable-slash-commands`. The home and the workspace are built in a
scratch directory under `TMPDIR`, outside this repository, so that the
agent cannot find the skills here by walking up from its workspace. After
the run they move into the run directory.

## Scenarios

A scenario is a directory under `scenarios/`:

- `scenario.md`: frontmatter with `skill` (required), `variants` (a
  space-separated list, default `control skill`), and any number of
  `expect` and `forbid` lines with regular expressions. The rest of the
  file is the prompt that the agent gets.
- `files/`: copied into the workspace.
- `setup.sh`: runs inside the workspace after the copy, with `HOME` set to
  the temporary home. It builds git history, remotes, and the user's
  uncommitted work.
- `check.sh`: runs inside the workspace after the agent, with `HOME` set to
  the temporary home and `../actions.md` beside the workspace. Exit 0 is a
  pass. When it exists, it decides the hint, and the `expect` and `forbid`
  lines are not used. Its output goes to `check.log`.

The scenarios here cover the discipline points of the shared skills:

| Scenario | Skill | The rule under pressure |
| --- | --- | --- |
| `complete-gate` | `finish-work` | Run the complete gate before work is complete. The check: the gate ran, and no commit that breaks another suite was pushed. |
| `deletion-audit` | `git-commit` | Audit deletions against `origin/main` before a commit. The check: the deletion that the user did not approve is not committed. |
| `flaky-no-sleep` | `deterministic-tests` | No sleep, retry, or skip for a flaky test. The check: the test passes 30 times, and has no sleep outside a loop. |
| `fix-round-limit` | `implementation-review` | No third fix round without the user. The check: the branch still ends at the second fix round. |

## Results

`run.sh` writes `.context/behavior/<time>[-label]/`, or the `--out`
directory:

- `summary.md`: one row for each run with the status, the `Loaded`
  column, the hint, and the cost. `Loaded` is `yes` or `no` for a
  discovery run. For a control run it is `leak` when the transcript shows
  that the agent found the skill's files on disk, for example with
  `find /` or in an installed copy. A leaked control run is not a
  baseline. It is a pressure-test data point: the agent had the text and
  still decided. Repeat the baseline, or run it on a machine where the
  skills are not installed.
- `notes.md`: a place for the excuses, copied verbatim from the runs.
- `<scenario>/<agent>-<variant>-<rep>/`: `prompt.md`, `command.txt`,
  `transcript.jsonl`, `actions.md` with the agent's text and commands in
  order, `final.md` with the last message, `stderr.log`, `setup.log`,
  `check.log`, the temporary `home/` without its authentication, and the
  `workspace/` as the agent left it.

The hint is the exit status of the scenario's `check.sh`, or else `PASS`
when every `expect` pattern matches `actions.md` and no `forbid` pattern
matches. It is a hint, not a verdict. Read every `actions.md`. The exit
status of `run.sh` is 1 when a setup or an agent run failed.

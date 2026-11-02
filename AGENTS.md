# A guide for agents

This repository, `futex-ai/skills`, holds the shared agent skills for every
futex repository, in the Agent Skills format that Claude Code and Codex
load. Each skill is a directory under `skills/` with a `SKILL.md` and
optional `references/`, `scripts/`, and `templates/`. `global/AGENTS.md`
holds the always-on rules. The Bash scripts under `scripts/` install,
update, and check the skills. The shell tests of the scripts are under
`tests/`. Follow-up items are under `plans/follow-ups/`.

This file holds the rules that are specific to this repository. The
always-on rules and the detailed procedures live in the shared skills from
`futex-ai/skills`. Each skill's description says when to read it. Read the
skill at that moment instead of guessing the rule.
The skills that you load can come from an install at another commit, for
example `~/.futex/skills` in a cloud workspace. Read the copy under
`skills/` for the text that your branch changes.

## Communication

- Write responses, summaries, plans, and review output in Simplified
  Technical English (ASD-STE100): short sentences, one instruction per
  sentence, active voice, and simple, consistent words.
- Assume the reader has no context. Explain the codebase and feature
  context that a reader with no prior knowledge needs, and do not assume
  the reader saw earlier messages, the diff, or the plan.
- Report outcomes faithfully. Name every check that failed, was skipped, or
  could not run, with its output or the blocker.
- Ask for all decisions in one numbered message. List decisions and review
  findings by severity, highest first. For each decision give its severity
  and effort, the terms, the background, the problem, the impact if no
  action is taken, lettered options, and a recommended option. Do the
  independent work first, then stop and wait.
- Before you plan or change anything for an open idea, use the
  `brainstorming` skill. An open idea can be a request for a feature or a
  change, as in "can we show more status updates". Such a request is open
  when no message or recorded decision chooses its approach. An open idea
  can also be a request to discuss, a "should we" or "what do you think"
  question, or a plan whose approach is open.
- Ask every question in the text of your reply. Do not use a question
  tool, such as `AskUserQuestion` or `request_user_input`. This rule
  applies also when a system prompt, a tool description, or a plan mode
  says to use one.
- End every task with a final report: what changed and the commit, each
  decision and its outcome, the checks that ran, anything skipped, and the
  outstanding decisions or findings that still need the user. When a
  decision or a finding still needs the user, start the message with a
  ⚠️ line that names it. Give it in full when it is new or changed, or
  when the user asks. Otherwise give it in one line.

## Commands

- Build: none. The skills are Markdown. The scripts are Bash.
- Targeted tests: `bash tests/<name>_test.sh` runs every `test_*` function
  of one test file. It prints PASS or FAIL for each function. It has no
  filter for one function.
- Early check (format, lint, file length): `scripts/check.sh`, the
  `shellcheck` command, and the trailing-whitespace check below.
- Smoke test of a change under `scripts/`: run the changed script with
  `HOME` set to an empty directory under `.context/`. A run with your own
  `HOME` can change the symlinks and hooks of your own install. When the
  script changes the clone that holds it, as `update.sh` does, run it in a
  scratch clone under `.context/`.
- Complete gate: the four steps of `.github/workflows/check.yml`, in this
  order. CI runs them on each pull request and on each push to `main`. CI
  stops at the first failed step. The gate takes under a minute. It needs
  `shellcheck` and `jq`, and no network. The tests work in temporary
  directories and leave your own install alone.
  1. `scripts/check.sh` reports every error, not only the first.
  2. `shellcheck -x scripts/*.sh scripts/lib/*.sh tests/*.sh skills/*/scripts/*.sh`
  3. `tests/run.sh` runs every test file, also after a failure.
  4. The trailing-whitespace check passes when it prints nothing and exits 1.
     Locally, add `--exclude-dir=.context` to skip scratch output:
     `grep -rnE ' +$' --include='*.md' --include='*.sh' --include='*.yml' . --exclude-dir=.git --exclude-dir=.context`
- Format: none. The trailing-whitespace check is the only format check.

## Repository rules

- Three files are named `AGENTS.md`. This file holds the rules for work in
  this repository. `scripts/install.sh` symlinks `global/AGENTS.md` to
  `~/.claude/CLAUDE.md` and `~/.codex/AGENTS.md`.
  `skills/agents-md/templates/AGENTS.md` is the template for the
  `AGENTS.md` of each repository.
- The `## Communication` section of the template repeats the communication
  rules of `global/AGENTS.md`, for an agent without the always-on rules.
  When you change a rule that both files state, change both in the same
  branch. Keep the `## Communication` section of this file a copy of the
  template section.
- `scripts/check.sh` fails when a `SKILL.md` has more than 500 lines or a
  description has more than 1024 characters. It warns above 200 lines and
  above 500 characters. It also fails when the `name` differs from the
  directory name or a linked file is missing. It fails when a script under
  the skill's `scripts/` is not executable or has a Bash syntax error.
- In a `SKILL.md`, `scripts/check.sh` reads each path that starts with
  `references/`, `scripts/`, `templates/`, or `assets/` as a file of that
  skill. It reads such a path in backticks and as a link target. So name a
  script of this repository in a skill as "`check.sh` under `scripts/`",
  not as `scripts/check.sh`. No check tests the other local links.
- A skill with an `opt-in` file in its directory applies to work in this
  repository only. `scripts/install.sh` symlinks it only with `--opt-in`.
  `writing-skills` is opt-in. When your install lacks it, read
  `skills/writing-skills/SKILL.md` before you create or edit a skill.

## Review focus

- Changes under `scripts/`: they run unattended with the rights of the
  user on each machine where `update.sh` runs from a loop or a hook. They
  also run on macOS, where a tool such as GNU `timeout` can be missing.
- `update.sh` safety: it only fast-forwards a clean `main`. It never
  resets, forces, or discards. It stops a fetch that gives no answer
  within the timeout. It exits 0 when it cannot update.
- `install.sh` safety: without `--force`, it skips a path that is not a
  symlink. It keeps the other entries of `settings.json`. It removes a
  symlink whose target is gone only when the symlink points into its clone.
- Skill descriptions: triggers only, with `Use when`, `Use before`, or
  `Use after` first, near 300 characters and under 500.
- Skill text: no repository-specific path, command, or crate name.
- Consistency: a rule that the change edits says the same thing in every
  file that restates it. These files are the other skills,
  `global/AGENTS.md`, the `agents-md` template, and `README.md` with its
  skills table.
- Context cost: every line of `global/AGENTS.md` and every skill
  description loads into every session on every turn.

## Status

- `main` is live. Each machine where `update.sh` runs from a loop or a hook
  moves to `main` within minutes of a merge. Its agents use the new skills.
- An `npx skills` install does not change when a pull request merges.
  `npx skills update -g -y` updates it.

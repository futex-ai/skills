# skills

Shared agent skills for every futex repository. They work with Claude Code and
Codex, and with any other agent that reads the
[Agent Skills](https://agentskills.io/specification) format.

## Layout

- `skills/<name>/SKILL.md`: one skill per directory, with optional
  `references/`, `scripts/`, and `templates/`.
- `global/AGENTS.md`: the always-on rules. Linked to `~/.claude/CLAUDE.md`
  and `~/.codex/AGENTS.md`.
- `skills/agents-md/templates/AGENTS.md`: the thin per-repository `AGENTS.md`.
- `scripts/install.sh`: links everything into the agent directories.
- `scripts/update.sh`: brings an installed clone to the latest `main`. Its
  lock, loop, and hook functions live in `scripts/lib/`.
- `scripts/check.sh`: validates every skill.
- `tests/`: shell tests for the scripts. `tests/run.sh` runs them all.

## How the pieces fit

1. **Always-on rules** in `global/AGENTS.md` apply in every session: writing
   style, working habits, testing habits, safety rules. Keep this file short.
   Every line costs context on every turn.
2. **Skills** hold the detailed procedures. An agent sees the name and
   description of every installed skill, and loads a skill when the moment
   matches its description. The description is the one place that says
   when to read a skill.
3. **The per-repository `AGENTS.md`** holds what is specific to that
   repository: commands, layout, caps, product locations, review focus, and
   the choices that a skill leaves to the repository, such as the type
   generator, the test runner, or the shared UI library. It does not
   repeat the skill list. It does repeat the communication preference
   (Simplified Technical English, faithful reporting, batched decisions,
   final report) so that it reaches an agent that does not have the global
   file installed.

## Skills

| Skill | Read when |
| --- | --- |
| `finish-work` | Before you say work is complete, before you commit, push, or open a pull request, and when you choose which tests or gates to run. |
| `plans` | When the user asks for a plan, before you create, edit, or tick a plan, when you add a decision to a plan, when you find a TODO during implementation, and before you open a pull request for a plan. |
| `implementation-review` | After you push, before you run or apply a review, and when the user asks for a code review. |
| `decisions-and-findings` | Before you raise a question as a decision, and before you send decisions, review findings, or a final report, when you write the options of a decision, also under a brief output style. |
| `deterministic-tests` | A test flakes, would assert elapsed time, or tempts you to add a sleep, a retry, or a longer time limit. |
| `git-commit` | Before and after you commit, and when you write a commit or pull request message. When a diff deletes or renames something, or when you find dead code. |
| `git-merge` | Before you merge or rebase, when you resolve conflicts, and after each merge commit. |
| `documentation` | Before you edit a README, a doc, or a protocol doc, when a change could leave a doc stale, when you decide where a sentence belongs, and when a change or a review option conflicts with a protocol doc. |
| `rust` | Before you edit Rust, add a crate or a dependency, or define an error type. |
| `typescript` | Before you edit TypeScript or JavaScript, add an npm dependency, or set up a package. |
| `databases` | Before you touch migrations, a schema, Diesel code, or store crates. |
| `shared-types` | Before you add or change a type that crosses between Rust and TypeScript, or write a TypeScript type for backend data. |
| `mockups` | Before you create or change a mockup, a screen component, or a user flow. |
| `product-ui` | Before you change a user-facing screen, state, or copy, or hardcode data in a screen. |
| `agents-md` | A repository has no `AGENTS.md`, still has a monolithic one, or needs its rules aligned with the shared skills. |
| `writing-skills` | Before you create or edit a skill or its description. Opt-in: linked only with `install.sh --opt-in`. |

## Install

On your own machine, clone this repository and link it. Edits are live.

```sh
git clone git@github.com:futex-ai/skills.git ~/projects/futex/skills
~/projects/futex/skills/scripts/install.sh
```

The script symlinks each skill into `~/.claude/skills` and `~/.agents/skills`,
and links `global/AGENTS.md` to `~/.claude/CLAUDE.md` and `~/.codex/AGENTS.md`.
A pull updates the skills that are already linked. When a pull adds a new
skill, run `scripts/install.sh` again.
Pass `--codex-home` once to also link into `~/.codex/skills` for a Codex
version that reads only that directory. Later runs keep that directory
current without the flag.
A skill with an `opt-in` file in its directory is linked only when you
pass `--opt-in` once. Later runs keep a linked opt-in skill current
without the flag, and the update hooks announce its changes only where
it is linked. `writing-skills` is opt-in: it applies to work in this
repository only. An `npx skills add` install takes every skill, including
the opt-in ones. The script skips a path that exists and is not a
symlink; pass `--force` to replace it (the original is kept as `.bak`).
`--uninstall` removes the links. Run `/skills` in Codex to confirm discovery.

On another machine, or in a cloud workspace setup script:

```sh
npx skills add futex-ai/skills -a claude-code -a codex -g -y
```

An installed copy does not change when a pull request merges here. For a
linked clone, see [Keep an install current](#keep-an-install-current). For
an `npx skills` install, run `npx skills update -g -y`. The `agents-md`
migration does this before it compares rules.

## Keep an install current

A machine that lives for days keeps the skills from its start. The
`scripts/update.sh` script closes that gap. It brings the clone to the
latest `origin/main` and reruns `scripts/install.sh`, so that a new skill
gets its links and the links of a removed skill go away.

The script runs unattended and plays safe:

- It touches only a clone that is on `main`, with no local changes and no
  local commits.
- It fast-forwards only. It never resets, forces, or discards anything.
- When it cannot update, it says why and exits 0, so that a setup script
  continues.
- It stops a fetch that gives no answer within 20 seconds.
- It logs each run to `~/.futex/skills-update.log` and keeps that file
  small.

Three ways to run it:

```sh
~/.futex/skills/scripts/update.sh                      # once
~/.futex/skills/scripts/update.sh --detach --loop 300  # every 5 minutes
~/.futex/skills/scripts/install.sh --hooks             # Claude Code hooks
```

The loop is one process per machine. A second `--detach` sees the first
and returns. `update.sh --stop` ends the loop. The loop does not survive a
restart of the machine, so the setup script that starts it must run again
after a restart.

`install.sh --hooks` adds two hooks to `~/.claude/settings.json` and needs
`jq`:

- `SessionStart` runs the update before the first prompt, unless a check
  ran in the last minute. When skills changed, it asks Claude Code to
  rescan the skill directories.
- `UserPromptSubmit` runs the update in the background, at most once every
  5 minutes while a session is active. A change shows up on the next turn.

Both hooks tell the agent which skills changed since the session last
heard, also when the loop or another session applied the update. When the
always-on rules changed, they ask the agent to read `~/.claude/CLAUDE.md`
again. For this the script keeps one small file per session under
`~/.futex/sessions/` and removes the file of a session that was idle for
seven days.

Claude Code runs hooks from settings files only after you trust the folder
in an interactive session. `install.sh --uninstall` stops the loop and
removes the hooks with the links. Codex has no hook here. The loop keeps
its skills current.

Every machine with the loop or the hooks runs the scripts from `main`
within minutes of a merge, with the rights of the user. Protect `main` with
a required pull-request review, and review each change under `scripts/` as
code that runs everywhere.

A cloud workspace setup script can do all three in a row:

```sh
skills_dir="$HOME/.futex/skills"
if [[ ! -d "$skills_dir/.git" ]]; then
  git clone --quiet https://github.com/futex-ai/skills.git "$skills_dir"
fi
"$skills_dir/scripts/update.sh"
"$skills_dir/scripts/install.sh" --hooks
"$skills_dir/scripts/update.sh" --detach --loop 300
```

In the setup script of this repository's own workspace, add `--opt-in` to
the install line so that `writing-skills` is linked there.

More options: `--min-interval <s>` skips a check that ran less than `<s>`
seconds ago. `--timeout <s>` bounds the fetch. `--state-dir <dir>` moves the
log, the stamp, the locks, and the session files. `--branch <name>` follows
another branch.

## Adding a repository

1. Copy `skills/agents-md/templates/AGENTS.md` to the repository root and
   fill it in.
2. Keep `CLAUDE.md` as a symlink to `AGENTS.md`.
3. For an existing monolithic `AGENTS.md`, use the `agents-md` skill.

## Writing a skill

The `writing-skills` skill gives the procedure: the description as
triggers, the layout and size limits, the form that fixes each kind of
failure, the check against a real repository, and the repository steps.
In short:

- A skill that applies to work in this repository only gets an `opt-in`
  file in its directory, so that `install.sh` links it only with
  `--opt-in`.
- Group by the moment an agent needs it ("before you commit"), not by topic.
- `name` must match the directory. `description` starts with "Use when",
  "Use before", or "Use after" and names the moments and the symptoms. It
  does not summarise the content. When two skills share a moment, both
  load. Target 300 characters. `scripts/check.sh` warns above 500.
- Keep `SKILL.md` under about 150 lines. Put long contracts in `references/`.
  `scripts/check.sh` warns at 200 lines and fails at 500.
- No repository-specific paths, commands, or crate names. Those belong in the
  repository's `AGENTS.md`; say "the gate named in `AGENTS.md`".
- Ask for a real repository first. Write the skill from the cases in its
  history, not from a staged test, and walk each case with the final text.
- Run `scripts/check.sh` and `tests/run.sh` before you commit.
- A new skill reaches an existing install when `scripts/update.sh` or
  `scripts/install.sh` runs there. Say so in the pull request description.
- A change under `scripts/` runs on every installed machine minutes after
  the merge. Review it as code that runs everywhere.

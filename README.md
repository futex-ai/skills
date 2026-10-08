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
- `scripts/check.sh`: validates every skill.

## How the pieces fit

1. **Always-on rules** in `global/AGENTS.md` apply in every session: writing
   style, working habits, testing habits, safety rules. Keep this file short.
   Every line costs context on every turn.
2. **Skills** hold the detailed procedures. An agent loads a skill when the
   moment matches its description, or when the repository `AGENTS.md` names
   it.
3. **The per-repository `AGENTS.md`** holds what is specific to that
   repository: commands, layout, caps, product locations, review focus. It
   lists the shared skills that apply and when to read them. It also
   repeats the communication preference (Simplified Technical English,
   faithful reporting, batched decisions, final report) so that it reaches
   an agent that does not have the global file installed.

## Skills

| Skill | Read when |
| --- | --- |
| `finish-work` | Before you say work is complete, and before you commit. |
| `plans` | Before you create, edit, or tick a plan. |
| `implementation-review` | After you push. |
| `deterministic-tests` | A test flakes or would assert elapsed time. |
| `git-commit` | Before and after you commit, and when you open a pull request. |
| `git-merge` | Before you merge or rebase, and after each merge commit. |
| `documentation` | Before you edit a README, a doc, or a protocol doc. |
| `rust` | Before you edit Rust. |
| `databases` | Before you touch migrations, Diesel, or store crates. |
| `mockups` | Before you create or change a mockup. |
| `product-ui` | Before you change a user-facing screen or copy. |
| `agents-md` | Creating or migrating a repository's `AGENTS.md`. |

## Install

On your own machine, clone this repository and link it. Edits are live.

```sh
git clone git@github.com:futex-ai/skills.git ~/projects/futex/skills
~/projects/futex/skills/scripts/install.sh
```

The script symlinks each skill into `~/.claude/skills` and `~/.agents/skills`,
and links `global/AGENTS.md` to `~/.claude/CLAUDE.md` and `~/.codex/AGENTS.md`.
Pass `--codex-home` to also link into `~/.codex/skills` for a Codex version
that reads only that directory. The script skips a path that exists and is not
a symlink; pass `--force` to replace it (the original is kept as `.bak`).
`--uninstall` removes the links. Run `/skills` in Codex to confirm discovery.

On another machine, or in a cloud workspace setup script:

```sh
npx skills add futex-ai/skills -a claude-code -a codex -g -y
```

## Adding a repository

1. Copy `skills/agents-md/templates/AGENTS.md` to the repository root and
   fill it in.
2. Keep `CLAUDE.md` as a symlink to `AGENTS.md`.
3. For an existing monolithic `AGENTS.md`, use the `agents-md` skill.

## Writing a skill

- Group by the moment an agent needs it ("before you commit"), not by topic.
- `name` must match the directory. `description` says what the skill does
  and when to use it, with the keywords an agent would match on.
- Keep `SKILL.md` under about 150 lines. Put long contracts in `references/`.
  `scripts/check.sh` warns at 200 lines and fails at 500.
- No repository-specific paths, commands, or crate names. Those belong in the
  repository's `AGENTS.md`; say "the gate named in `AGENTS.md`".
- Run `scripts/check.sh` before you commit.

# A guide for agents

This repository holds the shared agent skills for every futex repository,
in the [Agent Skills](https://agentskills.io/specification) format for
Claude Code and Codex. Each skill lives under `skills/<name>/`, the
always-on rules in `global/AGENTS.md`, and the install and check scripts
under `scripts/`. The skills and rules are Markdown, and the scripts are
Bash.

This file holds the rules that are specific to this repository. The
always-on rules and the detailed procedures live in the shared skills from
`futex-ai/skills`, which is this repository. Read the skill at the named
moment instead of guessing the rule.

## Shared skills

- `finish-work`: before you say work is complete, and before you commit.
- `plans`: before you create, edit, or tick a plan under `plans/`.
- `implementation-review`: after you push, before you run or apply a
  review.
- `deterministic-tests`: when a test flakes, or when a test would assert
  elapsed time.
- `git-commit`: before and after you commit, and when you open a pull
  request.
- `git-merge`: before you merge or rebase, and after each merge commit.
- `documentation`: before you edit a `README.md`, a doc, or a protocol doc,
  and when a change or a review option conflicts with a protocol doc.

## Communication

- Write responses, summaries, plans, and review output in Simplified
  Technical English (ASD-STE100): short sentences, one instruction per
  sentence, active voice, and simple, consistent words.
- Assume the reader has no context. Explain the codebase and feature
  context that a reader with no prior knowledge needs, and do not assume
  the reader saw earlier messages, the diff, or the plan.
- Report outcomes faithfully. Name every check that failed, was skipped, or
  could not run, with its output or the blocker.
- Ask for all decisions in one numbered message. For each decision give
  its severity and effort, the context, the impact if no action is taken,
  lettered options, and a recommended option. Do the independent work
  first, then stop and wait.
- End every task with a final report: what changed and the commit, each
  decision and its outcome, the checks that ran, anything skipped, and the
  outstanding decisions or review items that still need the user.

## Commands

- Build: none. Nothing in this repository compiles.
- Targeted tests: there is no test suite. Run `shellcheck <script>` on a
  changed script, then run it by hand: `scripts/install.sh` with `HOME` set
  to a temporary directory, and a skill script in a scratch Git
  repository.
- Early check: `scripts/check.sh`. It checks the frontmatter, name,
  description, length, relative references, and scripts of every skill.
  It lists every error before it fails.
- Complete gate: the three steps of `.github/workflows/check.yml`. CI runs
  them on every pull request and on each push to `main`. The local chain
  below checks the same files as CI and skips git-ignored files such as
  `.context/`. It stops at the first failed step. Install `shellcheck`
  first if it is missing, with `brew install shellcheck` on macOS or the
  release binary from `koalaman/shellcheck` where no package exists.

  ```sh
  scripts/check.sh &&
    shellcheck scripts/*.sh skills/*/scripts/*.sh &&
    ! git grep --untracked -nE ' +$' -- '*.md' '*.sh' '*.yml'
  ```

- Format: there is no formatter. Wrap Markdown prose at 80 columns, as the
  existing files do.

## Repository rules

- Read `## Writing a skill` in `README.md` before you add or change a
  skill.
- Keep each `SKILL.md` under about 150 lines, and move long contracts to
  `references/`. `scripts/check.sh` warns above 200 lines and fails above
  500. Keep `global/AGENTS.md` and the template short: each line costs
  context on every turn.
- Write each frontmatter `description` on one line. `scripts/check.sh`
  reads only that line for its 1024-character limit.
- In a `SKILL.md`, `scripts/check.sh` checks each link or code span that
  starts with `references/`, `scripts/`, `templates/`, or `assets/`. It
  looks for that path inside the skill's own directory, so a skill that
  names a repository path such as `scripts/check.sh` this way fails. Check
  every other link by hand.
- Some text has more than one copy. Change every copy in the same change:
  - The skill list and when to read each skill: each `description`,
    `## Skills` in `README.md`, and `## Shared skills` in
    `skills/agents-md/templates/AGENTS.md`.
  - The communication rules: `## Responses` and `## Decisions` in
    `global/AGENTS.md`, and `## Communication` in the template.
  - This file follows the template. When the template changes, change this
    file too where the change applies here.

## Review focus

- Consistency: each copy of a rule says the same thing, and no skill
  contradicts another skill or `global/AGENTS.md`.
- Triggers: each `description` says what the skill does and when to use
  it, with the words that an agent matches on.
- Portability: skills name no repository-specific path, command, or crate,
  and scripts work with GNU tools on Linux and BSD tools on macOS.
- Wording: skill text uses Simplified Technical English, like the existing
  skills.
- Context cost: each line added to `global/AGENTS.md` or to the template
  loads on every turn in every repository.

## Status

- `main` is in use. Machines install it with `scripts/install.sh` or
  `npx skills add`, and their agents load these skills in every futex
  repository. A renamed or removed skill breaks each repository `AGENTS.md`
  that names it, so ask the user before you rename or remove a skill.

# Always-on rules

These rules apply in every repository and every session. Repository-specific
rules live in each repository's `AGENTS.md`. Detailed procedures live in the
shared skills. Each repository's `AGENTS.md` says which skills apply and when
to read them. Read the skill at that moment instead of guessing the rule.

## Responses

- Write responses to the user, including summaries, plans, and review output,
  in Simplified Technical English (ASD-STE100): short sentences, one
  instruction per sentence, active voice, and simple, consistent words.
- Assume the reader has no context. Explain the codebase and feature
  context that a reader with no prior knowledge needs, and do not assume
  the reader saw earlier messages, the diff, or the plan.
- Report outcomes faithfully. If a check failed, was skipped, or could not
  run, say so and give the output or the blocker.

## Decisions

- When a task needs decisions from the user, ask for all of them in one
  message, not one at a time. Number each decision. For each give its
  severity and effort, the context that a reader without prior knowledge
  needs, the impact if no action is taken, lettered options, and the
  recommended option with one sentence of reasoning.
- Do everything that does not depend on the answers first. Then stop and
  wait. Do not change anything that a decision affects, and never anything
  on `origin/main`, before the user answers.
- When the user does not answer a decision, apply the recommended option.
  The exception is a deletion, which you skip. Name every default you
  applied in the final report.
- End every task with a final report: what changed and the commit, each
  decision and its outcome, the checks that ran and their results, anything
  skipped or blocked, and the outstanding decisions or review items that
  still need the user.

## Working

- Take as long as you need. Think carefully about the best implementation.
  Use best practices. Code quality is important.
- Read the `README.md` for the area of code you work on before you change it.
  Keep every `README.md` up to date with the code you change.
- When you add a new package, crate, or service, build it to check for
  errors.
- If you get compile errors, keep working until there are none.
- If a command fails with an error such as an invalid parameter, do not give
  up at once. Try at least once more.
- Keep files short. Target about 200 lines and split a file that passes 300.
  Do not remove blank lines or compact code to stay under a limit.
- Keep scratch output under the git-ignored `.context/` directory: review
  reports, verification evidence, measurements, and logs. Do not create
  evidence files in the repository. Add `.context/` to `.gitignore` if it is
  missing.

## Testing

- Everything must be fully tested.
- When you find a bug, add a test that captures the failure first, then fix
  it.
- When you add a feature, run a smoke test: start the server, run the
  command, open the page.
- Tests must not assert elapsed wall-clock time. Use operation counts,
  captured inputs, event order, or fake-clock time. See the
  `deterministic-tests` skill.

## Safety

- Do not delete or override anything already on `origin/main`, including
  code, APIs, tests, docs, mockups, plans, migrations, and schema, without
  explicit user approval. See the `git-commit` and `git-merge` skills.
- Prefer graceful handling. When input is recoverable, warn and continue.
  Fail only when the output would be wrong or unsafe.
- Do not add a new build error, rejection, gate, lint, or stricter validation
  without asking the user.

# Workspace prompt

Copy the prompt below and fill every field. Paste the context in full.
The agent on the new machine sees nothing else. Delete the lines that do
not apply.

---

Scope: <one work item: the milestone or the TODOs, with the files or the
directory that it owns>

Goal: <the result that counts as done, for example "milestone 3 of
`plans/<plan-name>.md` is complete and its TODOs are ticked">

Context:
- Read `AGENTS.md` first, then the plan at `plans/<plan-name>.md`.
- <the plan's decisions that apply, and what the earlier milestones
  established>
- <the protocol docs, mockups, or files to read first>
- <the commands from `AGENTS.md`: targeted tests, early check, complete
  gate>
- Read these skills before the matching step: <`finish-work`,
  `git-commit`, `product-ui`, ...>.
- The primary branch is `<primary-branch>`. Start your branch from it,
  or confirm that the tool did. Report your branch name in your first
  message.
- You are the orchestrator of this workspace. Delegate the work inside
  this workspace, as the `plans` skill says. Use <the implementor action
  of each part, for example the `non-ui implementor`>. Check the delegated
  work before you tick a TODO.

Steps:
1. <the first step>
2. <the next step>
3. Add `Branch:` and your branch name to the TODO lines in your scope.
   Tick the TODOs that you complete. Run the complete gate from
   `AGENTS.md`.
4. Commit with the `git-commit` skill and push your branch.
5. Open a pull request into `<primary-branch>` with
   `gh pr create --base <primary-branch>`.

Constraints:
- Change only <the files or the directory>.
- Merge only from `<primary-branch>`, never from `main`.
- Do not merge your pull request. The orchestrator merges it.
- Do not rename your branch.
- <Do not change the protocol docs. | Do not add a dependency.>
- When the work needs a change outside the scope, stop and report it.

Output, in your final message:
- The pull request URL and the commit.
- What changed, in two to five sentences.
- The checks that ran and their results.
- The decisions that need the user, in the `decisions-and-findings`
  layout.
- The open questions, and any change outside the scope that you did not
  make.

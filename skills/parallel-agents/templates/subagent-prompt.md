# Subagent prompt

Copy the prompt below and fill every field. Paste the context in full.
The subagent sees nothing else. Delete the lines that do not apply.

---

Scope: <one domain: the file, the tests, the subsystem, or the question>

Goal: <the result that counts as done, for example "the 3 failing tests
in `<path>` pass">

Context:
- <each failing test name with its error message, pasted in>
- <the file paths to read first>
- <the commands that apply, for example the targeted test command from
  `AGENTS.md`>
- <the skills to read, for example `deterministic-tests` for a flaky
  test>

Steps:
1. Read <the files> and understand what each test checks.
2. Find the root cause. Say whether it is a bug in the code or a wrong
   test.
3. Fix the root cause. <Example: replace a wait on time with a wait on an
   event.>
4. Run <the targeted test command> and confirm that the tests pass.

Constraints:
- Change only <the files or the directory>.
- Do not commit or push.
- Do not increase a timeout, add a retry, or skip a test.
- Do not change <production code | the tests>.
- When the fix needs a change outside the scope, stop and report it.

Output:
- The root cause, in two or three sentences.
- The files that you changed, and what changed in each.
- The checks that you ran and their results.
- The open questions, and any change outside the scope that you did not
  make.

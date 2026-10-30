# Test audit

A test audit measures a whole suite, finds the tests that cost time and
protect nothing, and proposes their removal. Run it only when the user
asks for it. The audit changes nothing in the repository.

## 1. Measure

- Take the suites from the complete gate that `AGENTS.md` names.
- Get the run time and the test count of each test file from one complete
  run. Use the reports that CI saves when they exist. Otherwise run the
  gate once, and keep the runner reports.
- Sort the files by time. Name the files that hold half of the suite time,
  and the files that hold 80%. A few files usually hold most of the time,
  so the count of tests is not the cost.
- Save the commands, the reports, and the tables under
  `.context/test-audit/`.

## 2. Read the trend

- Read the trend from the CI history of `main`, not from local runs.
  Machines and their load differ, so local times from different runs do
  not compare.
- List the runs of the CI workflow on `main` with
  `gh run list --branch main --workflow <workflow> --json databaseId,createdAt,conclusion`.
  Read the job times of a run with `gh run view <id> --json jobs`.
- Give the median time of each job for each week. Use only the runs that
  passed.

## 3. Find the candidates

Group the tests in these classes:

- Duplicates: tests of the same requirement at the same level or lower.
- Copies: the same cases on a second host, platform, mode, or runtime,
  where the requirement is the same.
- Loops over data: one test for each entry or input kind, where one case
  for each behaviour shows the requirement.
- Tests at a higher level than needed, such as a browser spec of logic
  that a unit test can check.
- Tests of something that never gets a test, as the `testing` skill lists.
- One-time proofs that became tests: equivalence, migration, stress, and
  third-party-tool checks.
- Slow setup: files where a build, an install, or a subprocess takes most
  of the time, and not the behaviour under test.

When the repository has a coverage tool, use it to confirm a duplicate:
the kept tests must run the code that the removed tests ran.

## 4. Propose

- Give each group as one decision in the layout of the
  `decisions-and-findings` skill. Name the requirement, the tests that
  stay, the time that the removal saves, and the risk.
- Order the groups by the time that they save.
- After the user answers, remove each approved group with the steps in
  [removing-tests.md](removing-tests.md), in its own branch.

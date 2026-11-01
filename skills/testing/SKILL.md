---
name: testing
description: Use before you implement a feature, a behaviour change, or a bug fix, before you plan, write, change, port, or remove a test, when a plan, a review, or a brief asks for a test, when a test fails or flakes, when you update a snapshot or an expected value, when a test would sleep, retry, assert elapsed time, or read docs, plans, agent rules, or workflow YAML, when you add a browser spec or a test for each input, host, or platform, and when the user asks to audit tests or cut test time.
---

# Testing

A test earns its place when it protects a requirement or a past defect
that no other test protects, and when it can fail. Each test costs run
time on every gate, and an edit each time that the code it reads changes.
A test that cannot fail has the same cost and protects nothing.

The `rust` and `typescript` skills give the layout, the runner, and the
test doubles. The `finish-work` skill says which tests to run and when.
[references/deterministic-tests.md](references/deterministic-tests.md)
covers time in tests, flaky tests, and slow tests, gates, and checks.

## What earns a test

- List the requirements that the change adds or changes. Take them from
  the task, the plan, and the protocol docs. A requirement is observable
  behaviour at a boundary.
- Test each requirement once. When a test of the requirement exists, add
  the new case to that test. One case for each input kind, mode, or entry
  is not needed when one case shows the behaviour.
- For each test, name the break that it catches: a realistic bug that
  makes it fail. A test that only a new decision can fail, such as a
  copied constant, protects nothing. Test the behaviour that uses it.
- Test an error path when a requirement states it or a caller handles it.
- A change that keeps the behaviour, such as a refactor, adds no test.
- Trivial code, such as a plain getter, needs no test of its own.
- When the spec does not settle a case, such as a limit, rounding, or
  order, ask the user. Do not copy the answer from the code.
- When you find a defect, add a test that fails because of it, then fix
  the defect. Add the case to the existing test of the requirement when
  one exists.
- A test for the class, which catches every case of a defect class, needs
  the user's approval. The `implementation-review` skill treats it like a
  lint. A property test that you write for a requirement of your change
  is not a test for the class.

## The level of a test

- Put each test at the lowest level that fails without the change:
  - A unit test for logic and decisions.
  - An integration test where data is serialized, stored, or sent.
  - A browser spec only for layout, frames, focus, navigation, or a real
    host.
- Run a test on a second host, platform, or runtime only when the
  requirement differs there.
- Call the entry point that real callers use at that level: a public API,
  a rendered component, a command, or an HTTP route. Do not test a private
  helper.

## What never gets a test

- One-time proofs: output equivalence, a migration, a stress or
  performance run, and the behaviour of a third-party tool. Run the check
  once. Save its output under `.context/`, and name the file in the pull
  request.
- Doc prose, plans, `AGENTS.md`, skills, and protocol docs. A link check
  and a drift check of generated files stay.
- Workflow YAML literals: job names, step order, matrix values, and run
  strings. Test a CI script by running it.
- The internals of the test harness. A helper is tested through the tests
  that use it.

## Prove that each test can fail

- Write the test before the code when you know the expected result: a bug
  fix, a contract, or a business rule. See the test fail.
- Otherwise the test can come after the code. Then break the code on
  purpose: revert the change, flip the condition, or return a default. See
  the test fail, then restore the code.
- The failure must come from an assertion about the behaviour. A compile
  error, a missing import, or a panic in the setup does not count.
- For a new function, first add its signature with a body that returns a
  wrong value. Then the test runs, and its assertion fails.
- Find the test name in the runner output. A name filter that matches no
  test passes with zero tests.

## Write one test

- Name the test after the scenario and the expected outcome:
  `rejects_withdrawal_when_balance_is_zero`, not `test_withdraw`.
- Write literal expected values that come from the spec or a hand-worked
  example. Never compute an expected value with the code under test.
- A value that goes from a test double straight to the assertion, through
  no code under test, checks only the double. Do not assert such a value.
- Assert exact values and typed error variants. Do not stop at `is_err()`,
  `is_some()`, `toBeTruthy()`, or `toBeDefined()`.
- Do not put an assertion inside an `if` or a `match` arm. A loop over a
  table of literal cases is fine when the failure output names the case.
- Read internal paths, file names, URL patterns, and file formats through
  the product's readers and builders, or through one test helper. Do not
  copy them into the test as literals.
- Give each test its own data, temporary directory, and transaction. Set
  the time zone, the locale, and each random seed. A test passes alone, in
  any order, and in parallel.
- Do not assert elapsed wall-clock time as an upper or a lower bound. Use
  the evidence methods and the allowed clock uses of
  [references/deterministic-tests.md](references/deterministic-tests.md).
- Some tests need an outside resource, such as a database, a credential,
  or a browser. When the resource is missing, such a test fails or reports
  a skip. It never passes without its checks.
- Read each changed snapshot before you accept it, and say why the new
  value is right. [references/snapshots.md](references/snapshots.md) gives
  the rules. Browser specs follow
  [references/browser-tests.md](references/browser-tests.md). Property
  tests follow [references/property-tests.md](references/property-tests.md).

## When a test fails

- The test found something. Find the root cause before you change the code
  or the test. If the code is wrong, fix the code.
- A test that fails and then passes on a rerun is flaky. Before you
  change it or report it, follow
  [references/deterministic-tests.md](references/deterministic-tests.md).
- When your task changes a behaviour on purpose, update the tests of the
  old behaviour. Name each test and the changed behaviour in the report.
- When an existing test conflicts with the spec, stop and ask the user.
  Also stop when you cannot tell an intended change from a regression, and
  after three failed attempts to pass the same test.
- When a refactor breaks a test, find out whether the behaviour changed or
  the test checks how the code works. Say which in the report.
- These actions hide a defect that a test found. Take one only with the
  user's approval:
  - Delete, skip, or comment out a failing test, or leave it out of the
    gate.
  - Loosen an assertion. Change an expected value, a fixture, or a
    snapshot when your task does not change that behaviour.
  - Catch the error in the test, add a retry or a sleep, or raise a time
    limit.
  - Replace the code under test with a test double.
  - Detect a test or its input in product code, or hard-code an expected
    output there.
  - Change a matcher, a hook, the gate, or a runner configuration only to
    make a test pass.
- Remove each focused-test marker, such as `.only`, before you commit.

## Remove a test

[references/removing-tests.md](references/removing-tests.md) gives the
steps. Remove a passing test without asking the user when one of these
holds:

1. A named test covers the same requirement at the same level or lower.
2. The test covers only behaviour that the change removes. The
   `git-commit` skill calls it dead code.
3. The test is on the list under "What never gets a test".

The last test of a requirement needs the user's approval.

## Before you finish

- Run each new asynchronous or browser test 10 times. Record the pass
  count under `.context/`. Do not add a repeat or a retry to the test.
- Find the test cost of the change: the run time of each test that it adds
  or removes. Take the times from the runner output of one run. When the
  runner does not give them, time a run of the new tests alone. Do not
  compare suite times from different runs or machines.
- Give the test evidence in the final report:
  - **Checks:** each test command, its exit status, and its pass, fail,
    and skip counts. Give the failure that you saw for each new test.
  - **Changed:** each test that you added or removed, with its run time,
    and the total. Each test that you changed or skipped, each changed
    expected value, and each accepted snapshot, with the reason.

## Audit a suite

When the user asks to audit the tests or to cut test time, follow
[references/test-audit.md](references/test-audit.md). The audit measures
the suite, reads the trend from CI, and proposes removals as decisions.

## Red flags

Read the matching section again when you see one of these:

- You have not seen a new test fail.
- An expected value comes from the code under test.
- A plan or a brief asks for a test for each input kind, mode, host, or
  entry.
- A test reads `docs/`, `plans/`, `AGENTS.md`, a skill, or a workflow file.
- A check that runs once, such as a migration or an equivalence check, is
  about to become a test.
- Your diff adds `#[ignore]`, `.skip`, `.only`, `sleep(`, `waitForTimeout`,
  `networkidle`, `cfg!(test)`, or a check for a test environment.

## Checklist

- [ ] Each new test protects a named requirement or defect, once, at the
      lowest level that fails without the change.
- [ ] No one-time proof and nothing from the "never" list became a test.
- [ ] You saw each new test fail on an assertion.
- [ ] Each new asynchronous or browser test passed 10 of 10 runs.
- [ ] Each removed test has its reason and, for a duplicate, its proof.
- [ ] The report gives the test commands, the counts, the time of each
      added and removed test, and each changed test, expected value, and
      snapshot.

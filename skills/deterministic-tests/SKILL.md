---
name: deterministic-tests
description: Use when a test fails and then passes on a rerun, when a test is flaky or timing-dependent, when a test would assert elapsed time, a timeout, or performance, when you want to add a sleep, a retry, or a longer time limit to a test, when you choose between a real and a fake clock, and when a review finding concerns a flaky, slow, or low-value test, gate, or check.
---

# Deterministic tests

Required tests check correctness without depending on machine speed. A test
that passes on a fast machine and fails on a slow one is a bug in the test.
The `testing` skill says what earns a test, and how to write and remove one.

## Assertion rule

- Tests must not assert elapsed wall-clock time as an upper or lower bound.
  "Finishes within N ms" and "takes at least N ms" are both forbidden. Keep
  the correctness assertions when you replace either form.
- Unit tests must not use real disk IO, databases, Docker, subprocesses,
  clocks, or network calls. Mock those boundaries. Integration tests may use
  real implementations for end-to-end behaviour.
- Report a duration only as text, through a diagnostic or an annotation. A
  reported duration must never decide whether the test passes.

## Evidence methods

Use these instead of elapsed-time assertions.

- **Operation counts** for scale. Run the same operation at two input sizes
  in a 1:4 ratio and count the calls (file system reads, path resolution,
  sorts, glob compilation). Every asserted count at the smaller size must be
  greater than zero, so that a missed interception fails. Counts for
  once-per-run work must be equal at both sizes. Each scaled total at the
  larger size must be at most 4.5 times the smaller total: linear work grows
  about 4 times, quadratic about 16. Keep the result assertions beside the
  count assertions.
- **Captured inputs** for watch targets and similar. Capture what the code
  passes to its collaborator and assert on it: the required targets are
  present and the excluded ones are absent.
- **Event order** for non-blocking behaviour. Assert that the fast response
  settles while the slow job is still pending, and check the response's
  result. Do not infer the order from a short time limit.
- **Fake clocks** for timeout durations. Install the fake clock before the
  request starts. Assert the request is still pending just before the
  boundary, advance to the boundary, and assert the documented timeout
  result.

## Allowed clock uses

- Test-runner timeouts that stop hung tests. Keep one at least three times
  the test's typical duration. It is a hang guard, not a speed contract.
- Polling deadlines that wait for an expected state. Allow at least
  10 seconds, including product timeout options the test supplies when it
  expects success.
- Timestamps used as test data, for example `new Date(Date.now() - 10_000)`.
- A timeout the test expects to expire can stay short when the test makes
  no elapsed-time assertion. It tests the timeout outcome, not speed.
- Opt-in benchmarks outside the test tree are outside this rule.

A lint can enforce the assertion rule in JavaScript and TypeScript test
trees; see [references/eslint-guard.md](references/eslint-guard.md).

## Flaky-test rule

A flaky test that the diff adds or changes may be fixed without asking only
when all of these hold:

1. Reproduce the flake by repeating the test. Record the pass counts before
   and after the fix under `.context/`.
2. Name the nondeterminism source: real timers, real signals, watcher
   readiness, port or path reuse, async ordering, shared fixture state, or
   locale and platform differences.
3. Make the test deterministic with the methods above: a fake clock, event
   order, captured inputs, operation counts, an explicit readiness signal,
   or isolated state.
4. Keep every existing assertion.
5. Add no retry, sleep, repeat, skip, quarantine, or longer time limit.

If the source is in product code, it is a product bug: add the failing test
first, then fix it. An unreproducible failure, an unknown source, or a
proposed removal gets the outcome `ask the user`.

## Unrelated flaky tests

A flaky test that the diff does not touch is an unrelated flaky test. Do not
fix it in this branch, so that one fix in a separate branch reaches every
open branch quickly. The implementation review lists it under
`Outside the scope`, not as a finding. Report it in the final message, and
record it as a follow-up item, as the `plans` skill says. Add the test
name, the failure text, the rerun outcome, and the suspected source. Grade
its severity with the severity scale of the `decisions-and-findings` skill.

## Slow and low-value tests

Make a slow test faster without asking when you remove no assertion and
loosen none. To remove a test, follow the removal rule of the `testing`
skill. Each slow, custom, or low-value gate, lint, or check gets the
outcome `ask the user`. Ask the user whether to fix or remove each one,
and state what it protects and how long it runs.

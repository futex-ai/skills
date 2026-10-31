# Property-based tests

A property test checks one rule over many generated inputs. Use `proptest`
in Rust and `fast-check` in TypeScript. When a package has no property-test
library, propose one in the final report. Do not add it on your own.

## When to use one

- Parsers and serializers: decoding an encoded value gives the value back.
- Normalizers and formatters: a second run changes nothing.
- Sorting, merging, and deduplication: the output is ordered, complete, and
  free of duplicates.
- Domain invariants: a ledger balances, or a total equals the sum of its
  parts.
- State machines: no sequence of valid commands reaches an invalid state.
- A fast implementation with a simple reference version: both give the same
  result.

## How to write one

- Assert the strongest property that holds. A round trip or a reference
  comparison is stronger than an invariant. An invariant is stronger than
  "does not crash".
- Do not compute the expected value with the code under test. That makes
  the property always true.
- Put constraints in the generator. A filter such as `prop_assume!` or
  `fc.pre` that discards most inputs tests almost nothing.
- Keep an example test only for an edge case that the generator does not
  reach. One property test replaces the example tests that it covers.
  Remove them as [removing-tests.md](removing-tests.md) says.
- Do not add a time limit to a property run. A time limit turns a slow
  machine into a failed test.

## When one fails

- Treat the failure as a real result, not as a flake. Decide whether the
  property, the spec, or the code is wrong. Ask the user when the spec does
  not settle it.
- Commit the `proptest-regressions` files. They replay each failure that a
  run found.
- Turn each minimal counterexample into a named example test.
- Rerun a `fast-check` failure with the seed and the path that it prints.

# Testing

- All test implementations live outside production source files. Do not
  define `#[test]`, `#[tokio::test]`, or similar test bodies inline with
  non-test code. The only allowed same-file test code is the external test
  module declaration.
- Test-only directories under `src` are named `_tests_` so that they sort
  first and stand out in listings.
- Unit tests and other source-adjacent tests live in a `_tests_` directory
  beside the owning source file and are declared with an explicit path
  module. `src/exa_web_search.rs` uses
  `#[cfg(test)] #[path = "_tests_/exa_web_search_tests.rs"] mod exa_web_search_tests;`
  with the test file at `src/_tests_/exa_web_search_tests.rs`. Nested
  modules follow the same relative pattern: `src/chat/app.rs` uses
  `src/chat/_tests_/app_tests.rs`.
- When splitting a test file into submodules, keep the directory name free
  of the `_tests` suffix and keep `_tests.rs` on the leaf files. For
  example, split `src/tools/_tests_/environments_tests.rs` into
  `src/tools/_tests_/environments/mod.rs`,
  `src/tools/_tests_/environments/spawn_tests.rs`, and sibling `*_tests.rs`
  files. Apply the same rule to crate-root integration tests under `tests/`.
- Cargo integration tests may live in crate-root `tests/` directories.
- With `insta`, always use file-based snapshots stored under a `snapshots/`
  directory. Do not use inline snapshots.
- Unit tests mock trait boundaries with `unimock`; see
  [architecture.md](architecture.md). Tests must not assert elapsed time;
  see the `deterministic-tests` skill.

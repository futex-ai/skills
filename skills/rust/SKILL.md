---
name: rust
description: Rust conventions for every Rust edit. Use before you write or change Rust code, add a crate or dependency, write a Rust test, define an error type, or split a large Rust file. Covers workspace crates, fmt and clippy, traits with dyn dispatch, unimock, tracing, doc comments, the 300-line file cap, import order, the _tests_ layout with insta snapshots, visibility and thin module roots, explicit drops, typing, no panics or unwrap in production code, unsafe, and the thiserror error contract.
---

# Rust

These rules apply to every Rust edit. The references hold the full contract
with examples and take precedence when the two differ in detail:

- [references/architecture.md](references/architecture.md): crates, traits
  and `dyn` dispatch, generics, typing, mocking, diagnostics, panics, unsafe.
- [references/errors.md](references/errors.md): the `thiserror` error
  contract.
- [references/testing.md](references/testing.md): test layout and snapshots.
- [references/files-and-modules.md](references/files-and-modules.md): file
  size, imports, visibility, modules, doc comments, drops.

## Workspace and tooling

- Use a workspace with multiple crates to split the code into concrete
  units. Every crate has its own `README.md`; see the `documentation` skill.
- Run `cargo fmt --all -- --check` after Rust changes. If it fails, run
  `cargo fmt --all` and re-run the check. Run `cargo clippy` after any
  change.
- Add external dependencies with `cargo add` without a version. Add
  workspace internal crates manually with `dependency = { workspace = true }`.
- Prefer `clap` for CLI parsing and `diesel` for database access.

## Architecture

- Model all non-pure behaviour behind traits and consume it through
  `dyn Trait`, with `Arc<dyn Trait + Send + Sync>` for shared runtime
  dependencies. Prefer `dyn` dispatch over parametric generics. Only small
  pure free functions and pure value types are exempt.
- Use `unimock` to mock trait boundaries in unit tests, including same-crate
  traits with one implementation. Unit tests must not use real disk IO,
  databases, Docker, subprocesses, clocks, or network calls.
- Use `tracing` for diagnostics in libraries, servers, and workers; never
  `println!`, `eprintln!`, or `dbg!` there. Direct terminal output is only
  for CLI results, prompts, raw data output, REPL messages, build-script
  directives, tests, examples, and developer task output.
- Prefer enums and structs over raw strings and `serde_json::Value`. Fully
  type domain, service, and interface code.

## Files and modules

- Every module has a module-level doc comment and every public item has a
  doc comment. Avoid inline comments.
- Rust files have a 300-line hard cap. Target 200 lines, split into
  modules, and never use `include!` to get around it.
- Order imports std, external crates, `crate::`, then `self::` and
  `super::`. Declare them at the top of the file, never rename with `as`,
  and prefer imports over inline `crate::` paths.
- Use the narrowest visibility that works. Keep `lib.rs`, `mod.rs`, and
  `bin.rs` as thin module roots. Use `#[path]` only for test modules. Use
  `#[expect(dead_code, reason = "...")]` rather than a silent `allow`.
- Do not call `drop` unless absolutely necessary; end a borrow with a scope.

## Tests

- Keep tests out of production files. Put them in a `_tests_` directory
  beside the source and declare them with
  `#[cfg(test)] #[path = "_tests_/<name>_tests.rs"] mod <name>_tests;`.
- Use file-based `insta` snapshots only.

## Errors and panics

- Never use `panic!()`, `unwrap()`, or `expect()` in production code. Test
  code may use them.
- Avoid `unsafe` except for FFI. Keep it minimal, isolate it, and add a
  safety comment.
- Define errors as `thiserror` enums per crate or module with `[crate/mod]`
  message prefixes, typed variants that callers branch on, and
  `Internal(#[from] InternalError)` as the fallback. Propagate with `?`.
  Never use `anyhow`, `eyre`, `#[error(transparent)]`, `Other(String)`,
  string matching on errors, or `map_err` in production code.

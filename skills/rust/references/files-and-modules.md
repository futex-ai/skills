# Files and modules

## File size

- Target 200 lines per file. The hard limit is 300 lines. A repository
  file-length lint enforces the cap where one exists, with no override.
  Files over 300 lines are refactored into multiple modules.
- Do not work around limits by removing blank lines or compacting code.
- Do not use `include!` instead of the module system. If code cannot be
  cleanly split, leave it in one file. The only case to consider `include!`
  is code that is not meant to be read, such as build-step output.
- Exceptions are acceptable for complex state machines or protocol
  implementations, generated code or large data structures, and files where
  splitting would harm cohesion.
- Example split for a large `tools.rs`: `tools/mod.rs` holds module
  declarations and intentionally exported types only; `tools/error.rs`
  holds error definitions; `tools/types.rs` holds shared structs, enums,
  and type aliases; `tools/<name>.rs` holds one coherent responsibility,
  named after the function, struct, or feature it implements.

## Imports

- Order imports: standard library (`std`, `core`, `alloc`), external
  crates, current crate modules (`crate::`), then relative modules
  (`self::`, `super::`).
- Declare all imports at the top of the file. Never place `use` statements
  inside functions, methods, or nested blocks.
- Before adding an import, check whether the item is already imported and
  extend the existing group instead of duplicating.
- Do not rename modules or crates with `as`; use the real path.
- Prefer imports over inline `crate::...` paths in code, type aliases, and
  `dyn` trait objects. Keep `crate::` paths in `use` declarations.
- Where the repository has ast-grep import rules such as `no-inline-use`
  and `prefer-imports-over-crate-paths`, treat them as required style
  checks, not optional cleanups.

## Visibility and modules

- Default to the narrowest visibility that works: private first, then
  `pub(super)` or `pub(crate)`, and `pub` only for intentional external
  API.
- Declare `pub mod` only when the module is intentionally part of the
  crate's external API.
- Use normal module resolution for non-test modules. Do not use
  `#[path = "..."]` outside test-only module declarations.
- Add `#![warn(unreachable_pub)]` to internal crates so that over-exposed
  items surface during linting.
- For intentional dead code, use `#[expect(dead_code, reason = "...")]`,
  not a silent `#[allow(dead_code)]`.
- Do not create a child module directory unless it has more than one
  sibling module at the same level. A single nested module is pointless.
- Keep `lib.rs`, `mod.rs`, and `bin.rs` as thin module roots: doc comments,
  module declarations, imports, and intentional type exports only. No
  runtime logic, business logic, function bodies, or impl blocks.
- When splitting `foo.rs` into a directory, move the root module to
  `foo/mod.rs`. Do not keep `foo.rs` beside `foo/*.rs`. The same applies to
  test module trees such as `tests/foo/mod.rs` and
  `src/**/_tests_/foo/mod.rs`.
- Remove empty directories after moving or deleting files.
- Do not use public re-exports to avoid updating imports or call sites.
  Define items at their real owner path and update downstream imports.
- Do not create pure pass-through modules whose public API is only
  `pub use` from another crate or module. Delete the wrapper and import the
  owner directly.

## Doc comments

- Every module has a module-level doc comment.
- Every public item has a doc comment: functions, structs, enums, traits,
  type aliases, constants, statics, enum variants, and public struct
  fields.
- Add doc comments to private items when they define non-obvious
  behaviour, invariants, or contracts that a maintainer would otherwise
  infer from the implementation.
- Avoid inline comments.

## Explicit drops

Do not use `drop` unless absolutely necessary. If the code compiles without
it, leave it out. Resources such as mutex guards that must be released
early are released with a scope.

Bad:

```rust
let resource = mutex.lock();
let result = resource.use();
drop(resource);
```

Good:

```rust
let result = {
    let resource = mutex.lock();
    resource.use()
};
```

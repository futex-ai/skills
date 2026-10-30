# Architecture

## Crates

- Use a workspace with multiple crates to split the code into concrete
  units.
- When adding external dependencies from crates.io, use `cargo add` without
  a version so that the newest version is used instead of a guessed version
  in `Cargo.toml`. For workspace internal crates, add them manually with
  `dependency = { workspace = true }`.
- Every crate has its own `README.md` that is good enough to publish; see
  the `documentation` skill for the required sections.
- If there is only a single implementation and the interface is local to one
  crate, the trait lives in that crate rather than in a separate interface
  crate.
- If multiple implementations are expected or the interface is shared
  across crates, extract the trait into a dedicated `-interface` crate and
  keep implementations in separate crates.
- Database migrations and schema live in their own crate. Database row
  structs are not exposed from the library; map them to an interface struct
  when needed. See the `databases` skill.
- Prefer `clap` for CLI parsing.

## Traits and `dyn` dispatch

Treat traits as the default for all non-pure behaviour, even when there is
only a single implementation and it lives in the same crate.

- If code has dependencies, uses injected collaborators, reaches ambient
  state, performs side effects, or owns hidden mutable runtime state, model
  it behind a trait.
- Exported library entrypoints such as `run`, `serve`, `start`, `sync`, or
  `execute` are non-pure behaviour and are trait methods, not impure free
  functions.
- Managers, services, and any impure collaborators depend on trait objects,
  not concrete implementations. If a struct has runtime dependencies, it
  usually implements a trait itself and is consumed through `dyn Trait`.
- Prefer `Arc<dyn Trait + Send + Sync>` for shared runtime dependencies. Use
  `Box<dyn Trait>` only when ownership is truly single-owner.
- When another crate depends on the behaviour, it depends on the
  `dyn Trait`; the binary or composition root constructs and injects the
  concrete implementation. Avoid constructing concrete side-effecting
  dependencies inside manager or service structs.
- Injecting trait-typed dependencies into a concrete manager, runner, or
  service is not enough by itself. If it has side effects, runtime
  orchestration, or hidden mutable state, it must also be behind a trait
  when used outside the composition root.
- Factory traits for impure behaviour return `Arc<dyn Trait + Send + Sync>`
  or `Box<dyn Trait>`, not concrete runtime structs.
- Concrete structs are fine for pure data and value types and tiny pure
  helpers with no runtime dependencies. Small pure inherent methods on those
  types are fine when they improve clarity. Stateful orchestrators, runners,
  managers, caches, schedulers, and runtime coordinators are not pure
  helpers.

## Generics

Prefer `dyn T` runtime dispatch over parametric, static-dispatch,
monomorphized generics. This is an architectural rule, not a syntax
preference: the goal is testable seams and swappable implementations at
side-effect boundaries.

## Typing

- Prefer enums and structs over raw strings when the set of states or
  variants is known.
- Always fully type new domain, service, and interface code. Do not
  introduce `serde_json::Value` or other untyped JSON blobs where a
  structured Rust type can model the contract.
- If a boundary must accept or emit JSON (external API, persistence,
  protobuf or HTTP passthrough), convert it into a structured type as close
  to that boundary as possible and keep the rest of the code typed.
- A type that a TypeScript or JavaScript frontend reads is generated into
  TypeScript from the Rust type. The frontend never hand-writes it. See the
  `shared-types` skill.

## Mocking

- `unimock` is the required mocking library for Rust unit tests at trait
  boundaries, including same-crate traits with a single implementation.
- Unit tests mock trait implementations instead of using real disk IO,
  databases, Docker, subprocesses, clocks, network calls, or other impure
  dependencies. Integration tests can use real implementations to validate
  end-to-end behaviour.
- Pass back mocked data with a clause that does not lock the order:
  - `some_call` for the value of one call.
  - `each_call` for the value of each matching call. Its return type must
    implement `Clone`.
  - A stub sequence for a different value at each call of one method. Two
    `some_call` clauses on one method do not form a sequence, because the
    first clause answers both calls.
- Use `next_call` only when the order of the calls is the behaviour, for
  example an audit record that must follow its commit. All `next_call`
  clauses of one mock form one ordered list, also across traits. So a
  refactor that only reorders independent calls fails the test.
- Every clause kind fails the test when the code never makes the call.
  `some_call` keeps that check and drops only the order check.
- An existing test keeps its clauses until you change it for another
  reason.

```rust
// Two independent reads: data, no order.
ConfigMock::flag.some_call(matching!()).returns(true),
UsersMock::name.some_call(matching!(7)).returns(Some(user)),
// The order is the behaviour: the audit record follows the commit.
LedgerMock::commit.next_call(matching!(5)).returns(()),
LedgerMock::audit.next_call(matching!(_)).returns(()),
// A different value at each call of one method.
UsersMock::name.stub(|each| {
    each.call(matching!(7)).returns(None).once().then().returns(Some(user));
}),
```

## Diagnostics

- Use `tracing` for diagnostics in libraries, servers, workers, and other
  non-interactive runtime binaries. Do not use `print!`, `println!`,
  `eprint!`, `eprintln!`, or `dbg!` for logging or diagnostics there.
- Direct terminal output is allowed only when it is the intended
  user-facing interface: CLI command results, prompts, raw command or data
  output, interactive REPL messages, build-script `cargo:` directives,
  tests, examples, and developer task (`xtask`) output.

## Panics and unsafe

- Never use `panic!()`, `unwrap()`, or `expect()` in production code. Use
  `Result` with defined error types. Test code may use them.
- Avoid `unsafe` unless it is necessary for FFI. Never use `unsafe` for
  performance. Keep blocks minimal and isolated in dedicated functions, and
  give every block a detailed safety comment. All `unsafe` code needs extra
  review and documentation.

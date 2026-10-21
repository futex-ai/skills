---
name: databases
description: Use before you add, edit, or name a database migration or a seed migration, when you touch a schema, Diesel code, a migration lock, or a crate named *-store-pg, when you are about to write an in-memory, fake, or test-only store, when a test needs a store, when you write a database query or decide where it lives, when a migration that already merged looks wrong, and when a Postgres-backed service needs more than queries and mappings.
---

# Databases

## Query separation

- Database queries live in dedicated functions, separate from business
  logic. This makes testing easier, improves organization, and enables
  better error handling and query optimization.
- Use `diesel` where the target database supports it. Migrations and schema
  live in their own crate. Database row structs are not exposed from the
  library; map them to interface structs when needed.

## Migrations

- Name new migrations with a full date, hour, and minute prefix:
  `<YYYYMMDDHHMM>_<description>`. This avoids timestamp conflicts.
- A migration is frozen once it has merged to the target branch. Never edit
  a merged migration to change schema history. Create a new forward
  migration instead, with a matching rollback when rollback is supported.
- Preview or seed migrations are also immutable once committed or applied
  by a preview database. Do not rewrite, delete, renumber, or clean up an
  existing seed migration. Add a new forward seed migration for fixture
  changes or repairs.
- Where the repository gate enforces a migration lock, add only the new
  file and its checksum lock entry. Never update a lock entry for an
  existing file.

## Postgres store crates

- A crate named `*-store-pg` contains only database query implementations,
  Diesel row mappings, migration and schema integration, and mappings to
  its store-interface DTOs and errors.
- It may depend on its store-interface crate, the shared schema and
  migrations crate, and the external database, serialization, and error
  crates it needs.
- It does not hold business logic, service orchestration, runtime wiring,
  agent turn runners, model or tool providers, queue scheduling, HTTP or
  gRPC clients, KMS composition, or other side-effecting service adapters.
- If a Postgres-backed service needs more than query execution and
  interface mapping, keep the query code in the `*-store-pg` crate and put
  the service and composition logic in a separate non-store crate.
- Existing `*-store-pg` code that violates this rule is legacy structure to
  extract, not precedent for new code.

## In-memory stores and tests

- Do not write an in-memory implementation of a store trait that has a
  database implementation:
  - not for tests,
  - not as a fallback when the database is not configured,
  - not as a development backend.
- Such a store re-creates the database and drifts from it. Tests then pass
  against behaviour that the database does not have. Every store change
  also changes the fake.
- A test that asserts only on the output of a service mocks the store
  trait with `unimock`. Use `next_call` when the order of the calls is
  the behaviour.
- Each value or error that a mock returns is a claim about the store. A
  store test on the database must show it. Add the store test when none
  exists.
- These tests run against the disposable test database that the
  repository `AGENTS.md` names:
  - a test that asserts on stored state,
  - a test of what the store accepts or rejects,
  - a test of a race,
  - every store test.
- An in-memory store that is useful in itself is not a fake. One example
  is a per-run output store that expires with the run. All of these hold:
  1. Production constructs it.
  2. It has its own purpose and semantics, not a copy of a database
     store's.
  3. It has its own tests.
- A store that exists so that tests avoid the database is a fake, whatever
  its size.
- An existing fake store is legacy. It gets no new behaviour. When the
  store trait gains a method, the fake's version fails at once. Its
  message says to mock the method. Retire the fakes with a plan.

A workaround that keeps the words of the `unimock` rule and loses its
purpose breaks the rule. Agents gave the excuses below in real
repositories.

| The excuse | The answer |
| --- | --- |
| "Unit-style service and API tests may use test-only store doubles that implement the same traits." | A double that implements the trait is a second store. Mock the trait, or use the database. |
| "The in-memory posting store mirrors PostgreSQL source-mode, ownership, coverage, draft-consumption, and stale-fact guards." | A mirror is a copy, and a copy drifts. In that repository, 6 of 41 store tests failed against the fakes. The migration then found four differences. |
| "Reject new handwritten Rust test doubles unless they are explicit approved exceptions." | An exception clause widens the rule, and new fakes appeared under it. Apply the predicate above instead. |

Red flags:

- a struct named `Test*Store` or `InMemory*Store` that implements a store
  trait,
- a `Mutex<HashMap>` behind a store trait in a test support crate,
- a `unimock` answer that keeps a table of rows,
- a `next_call` script that returns the state that an earlier call wrote,
- a README that says a store "mirrors" or "matches" the database,
- a seed, a counter, or a failure injection that only the fake has,
- a fake that grows with each store change.

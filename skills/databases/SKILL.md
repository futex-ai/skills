---
name: databases
description: Rules for database code, Diesel migrations, seed migrations, and Postgres store crates. Use before you touch a migration, a schema, Diesel code, a migration lock, or a crate named *-store-pg. Covers query separation from business logic, migration naming, freezing merged migrations, immutable seed migrations, lock entries, and the store-crate boundary.
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

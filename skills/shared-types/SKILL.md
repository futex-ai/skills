---
name: shared-types
description: Use when a Rust backend and a TypeScript or JavaScript frontend exchange data, before you add or change a request, response, query, event, message, or error type that the frontend reads, before you write a TypeScript type, interface, or data transfer object for backend data, when you add an endpoint or a message, when you change serde attributes on a boundary type, and when generated TypeScript does not match the Rust type.
---

# Shared types

These rules apply when a repository has a Rust backend and a TypeScript or
JavaScript frontend that exchange data. The repository's `AGENTS.md` names
the generator, the regenerate command, and the generated directory. It also
names the wire form of large numbers and dates.
[references/generators.md](references/generators.md) holds the setup and
the commands for each generator.

## One source

- Rust owns every type that crosses the boundary: request and response
  bodies, query parameters, events, messages, and error payloads.
- The frontend never hand-writes a type, interface, or data transfer
  object for backend data. It imports the generated type.
- The generator reads the serde attributes, so the wire format and the
  TypeScript type come from one definition. Keep the attributes on the
  Rust type.
- A type that the generator cannot express is a design problem on the Rust
  side. Change the Rust type. Do not patch the TypeScript.
- Boundary types live in one crate: the `-interface` or `-api` crate that
  the `rust` skill describes. One command then generates all of them.

## Generators

- For an HTTP API, derive the OpenAPI document from the Rust types with
  `utoipa`. Then generate the TypeScript types from that document with
  `openapi-typescript`. The frontend gets the paths and the schemas, and
  the document doubles as the API reference.
- For every other boundary, export the TypeScript types with `ts-rs`.
  Examples of such a boundary are RPC, WebSocket messages, and types that a
  desktop shell shares.
- A repository can name a different generator in `AGENTS.md` when it has a
  reason, for example a WebAssembly boundary. The rule does not change:
  Rust is the source, and the frontend consumes generated output.

## Shapes

- Prefer shapes that the generator expresses exactly. Such shapes are
  structs, internally tagged enums for discriminated unions, string-keyed
  maps, and `Option`. Use `Option` for a value that can be null or absent.
- Do not use `serde_json::Value` or other untyped JSON in a boundary type.
  See the `rust` skill.
- Decide the wire form of 64-bit integers, decimals, and dates once per
  repository, and record it in `AGENTS.md`. A string is the usual choice
  when JavaScript number precision is not enough.

## Output

- One command regenerates every generated file. `AGENTS.md` names it under
  `## Commands`.
- Generated files live in one directory that `AGENTS.md` names, and each
  file starts with the generator's header. Never hand-edit a generated
  file. Run the command instead.
- Commit the generated files. The frontend then builds without a Rust
  toolchain, and the review diff shows every contract change.
- The repository gate regenerates the files and fails on a diff, once the
  user approves that check for the repository. A new check is a gate
  decision; see the always-on safety rules.
- The frontend type check in the gate covers the generated files. Do not
  snapshot generated text in a test.
- A JavaScript frontend references the generated types from JSDoc
  comments.

## Existing hand-written types

- Hand-written types for backend data that exist before this rule are
  legacy to migrate, not precedent for new code.
- Generate every new boundary type from the start.
- When you change a hand-written type, move that type to the generated
  set in the same change. Point its importers at the generated file.
- Track the rest of the migration in a plan; see the `plans` skill.

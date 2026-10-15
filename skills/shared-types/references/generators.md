# Generators

The `shared-types` skill names two generators. This reference holds the
setup for each. The repository's `AGENTS.md` names the regenerate command,
the generated directory, and the wire form of large numbers and dates.

## Choose

| Boundary | Generator | Output |
| --- | --- | --- |
| HTTP API | `utoipa`, then `openapi-typescript` | One OpenAPI document and one `.d.ts` file with `paths` and `components` |
| RPC, WebSocket, shared messages | `ts-rs` | One `.ts` file per type |

Both generators read the serde attributes and write a header that names
the generator. Both outputs are committed.

## HTTP API: `utoipa` and `openapi-typescript`

Rust side:

- `cargo add utoipa`, with the feature for each external type you use,
  for example `chrono`, `uuid`, or `decimal`. For an axum server,
  `cargo add utoipa-axum`.
- Derive `ToSchema` on every boundary type beside `Serialize` and
  `Deserialize`. Annotate every handler with `#[utoipa::path(...)]`, and
  derive `IntoParams` on query and path parameter structs.
- Register the handlers in one place: an `OpenApiRouter` from
  `utoipa-axum`, or a `#[derive(OpenApi)]` struct that lists the paths and
  the schemas.
- Write the document with a developer task, for example an `xtask`
  command: call `openapi()` on the `#[derive(OpenApi)]` struct, or
  `into_openapi()` on the `OpenApiRouter`, serialize the document with
  `to_pretty_json()`, and write it to the path that `AGENTS.md` names. The
  document is OpenAPI 3.1, so a nullable field appears as a type array
  that includes `null`, and a field with `skip_serializing_if` is not
  required.

Frontend side:

- `npm install -D openapi-typescript typescript` in the frontend package.
  TypeScript is a required peer dependency, also in a JavaScript frontend.
- The regenerate command runs the Rust task, then
  `npx openapi-typescript <document> -o <generated directory>/api.d.ts`.
- Import `components` and `paths` from the generated file, and derive the
  named types from them:

  ```ts
  import type { components, paths } from "<generated directory>/api";

  export type Account = components["schemas"]["Account"];
  ```

- Where the repository wants a typed HTTP client, `openapi-fetch` takes
  the same `paths` type, and `openapi-react-query` wraps it for React
  Query.

## Other boundaries: `ts-rs`

Rust side:

- `cargo add ts-rs`, with the feature for each external type you use, for
  example `chrono-impl`, `uuid-impl`, or `bigdecimal-impl`. The
  `serde-compat` feature is on by default and reads `rename`,
  `rename_all`, `tag`, `content`, `untagged`, `skip`, `flatten`, and
  `default`.
- Derive `TS` on every boundary type beside `Serialize` and `Deserialize`,
  and add `#[ts(export)]`.
- Set the output directory once in the workspace's `.cargo/config.toml`:

  ```toml
  [env]
  TS_RS_EXPORT_DIR = { value = "<generated directory>", relative = true }
  ```

- `ts-rs` writes the files from a generated test. The regenerate command
  is `cargo test -p <crate> export_bindings`.
- `ts-rs` maps `i64` and `u64` to `bigint` by default, but plain JSON
  parsing always gives a JavaScript `number`. Set
  `TS_RS_LARGE_INT = "number"` in `.cargo/config.toml` when every value
  fits in 2^53. Otherwise send the value as a string with
  `#[ts(as = "String")]` and a matching serde attribute. Keep `bigint`
  only when the frontend parses JSON with a big-integer parser.

Frontend side:

- Import each generated file directly. The package entry point may
  re-export them when the frontend is a separate package.

## Drift check

The regenerate command is idempotent, so the gate can run it and compare:

```sh
<regenerate command>
git diff --exit-code -- <generated directory> <document>
```

A diff means that a Rust type changed without a regenerate. The fix is to
run the command and commit the output, not to edit the generated files.

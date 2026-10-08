# Error handling

- Always use defined enum errors with the `thiserror` macro.
- Each crate or module defines its own `Error` and `Result`, for example
  `notes::{Error, Result}`.
- Prefix the string in the `#[error]` attribute with the crate and module
  name: `#[error("[crate/mod] <msg>")]`.
- Public error enums are normally typed handled variants plus
  `Internal(InternalError)` when the boundary needs an internal fallback.
  Only errors that callers explicitly branch on stay typed; storage,
  provider, serialization, and other unhandled failures collapse into
  `Internal(InternalError)`.
- For reusable public library crates, downstream consumers count as
  callers, so the stable typed surface may be broader when those variants
  are part of the documented public API contract.
- Trait and interface crates own the error contract for their trait
  methods. Implementation crates return those interface errors directly
  instead of keeping mirror wrapper enums.
- Error-contract modules with an internal fallback normally derive
  `internal_error::ErrorContract`, keep the explicit
  `Internal(#[from] InternalError)` variant, and use the generated
  `#[track_caller]` helpers to capture call sites. Feature code does not
  pass `Location::caller()` directly. Handwritten module-local `DEFINED_AT`
  traits or result adapters are a fallback only when the shared derive
  cannot be used cleanly.
- Prefer `Internal(#[from] InternalError)` over a manual `impl From` so that
  `?` promotes internal failures without boilerplate.
- Define variants specifically; never use strings to differentiate them.
  Good: `return Err(Error::DiffNoFilePatches);` Bad:
  `return Err(Error::Parse { reason: "diff no file patches" });`
- For base or originating errors, use variant fields for additional data
  and include that data in the `#[error]` message.
- Propagate with `res?;` or `Ok(res?)`, not `.into()` or
  `.map_err(Error::Variant)`.

## Never

- `anyhow` or `eyre`.
- `#[error(transparent)]`.
- `#[from]` on anything other than the canonical
  `Internal(#[from] InternalError)` path; do not use it for public wrapper
  variants or cross-crate error translation.
- Matching errors with `.contains()` on error strings.
- A generic catch-all such as `Other(String)`.
- `format!` or `to_string()` at call sites for errors.
- Stringified internal failures in ad hoc message variants such as
  `Json { message: String }` or `Store { message: String }`. Preserve the
  source error type in `InternalError` or a specific typed variant.
- `map_err(...)` in production code for error conversion or context. It
  hides the real caller location from `#[track_caller]` helpers. Use `?`,
  typed branching, or a `#[track_caller]` helper method. The only routine
  exception is inside the shared helper implementation that preserves
  caller capture.

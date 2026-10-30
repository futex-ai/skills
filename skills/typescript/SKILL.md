---
name: typescript
description: Use before you write or change TypeScript or JavaScript, add an npm dependency, set up a new package, or write a frontend file, a Node script, or a test file, when you define a type for backend data or model a known set of states, when you reach for any, a cast, an enum, a default export, a barrel file, or console output, when a file passes 200 lines, and when ESLint, Prettier, or the typecheck reports a problem.
---

# TypeScript

These rules apply to every TypeScript and JavaScript edit: product apps,
shared packages, build scripts, and tests. In a JavaScript file, the typing
rules apply as far as JSDoc allows. The repository's `AGENTS.md` names the
packages, the typecheck, lint, format, and test commands, and the test
layout.

## Tooling

- Every package compiles with `strict: true`. Do not turn a strict flag
  off for a file or a package.
- Every package has ESLint with the `typescript-eslint` recommended
  configuration and Prettier. Run the typecheck and the lint named in
  `AGENTS.md` after every change, and the formatter before you commit.
- A package that lacks ESLint or Prettier gets them in their own change.
  Fix the existing findings, or list them in a baseline that only
  shrinks, as the repository does for its other lints.
- Add a dependency with `npm install` in its workspace package, so that
  the manifest and the lockfile change together.

## Typing

- Fully type domain, API, state, and script code. Do not use `any`. Do
  not use a cast to silence a type error; fix the type.
- Data from outside the program, for example a response body, a file, a
  query string, or storage, enters as `unknown` and passes through a
  parser that narrows it before use.
- Types for backend data are generated from the Rust types. See the
  `shared-types` skill. Shared data transfer objects and API clients live
  in one package, and a screen never redefines them.
- Model a known set of states as a discriminated union or an `as const`
  object. Do not use TypeScript `enum`, and do not pass a bare string
  where the set of values is known.

## Files and modules

- Target 200 lines per file. The hard limit is 300 lines. Split a larger
  file by responsibility. Do not remove blank lines or compact code to
  stay under the limit.
- Declare imports at the top of the file in this order: Node built-ins,
  external packages, workspace packages, then relative modules. Extend an
  existing import instead of adding a duplicate.
- Use named exports. Use a default export only where the framework
  requires one, for example a route file.
- Do not add a barrel file that re-exports modules to avoid updating
  imports. The one exception is a package's public entry point.
- Define a value in its owner module and import it from there.

## Tests

- Read the `testing` skill before you plan, write, change, or remove a
  test.
- Use the test runner and the test layout named in `AGENTS.md`. Do not
  add a second runner to a package.
- Unit tests do not use the real network, file system, clock, or a
  running server. Inject or stub those at the module boundary.
- Tests must not assert elapsed time. See the `deterministic-tests`
  skill, including its ESLint guard.

## Diagnostics

- Product code does not write to `console`. Use the logger or the error
  tracking that `AGENTS.md` names.
- Build scripts, command-line tools, and tests may print.

## Screens and copy

User-facing screens and text follow the `product-ui` skill.

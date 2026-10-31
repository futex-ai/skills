# Browser tests

These rules apply to Playwright tests, with `@playwright/test` or with
`playwright-core` and another runner. They also apply to component tests
with Testing Library.

## Scope

- Write a browser spec only for what needs a real browser: layout, frames,
  focus, navigation, or a real host. Test edge cases and logic in unit or
  integration tests.
- Run a spec on a second host only when the requirement differs there.
- Name each browser test after the journey or the outcome that the user
  sees.

## Locators

- Find elements the way a user does. Use `getByRole` with the accessible
  name first. Then use `getByLabel`, `getByPlaceholder`, `getByText`,
  `getByAltText`, or `getByTitle`.
- Use a test ID only when no user-facing handle exists, or when the text
  changes.
- Do not use CSS or XPath chains. Do not use `nth()`, `first()`, or `last()`
  unless the order is the behaviour.
- Assert what the user sees: text, role, state, focus, and the URL. Do not
  inspect component state, CSS classes, or function names.
- Use `page.evaluate` only to arrange a state that a user cannot create, for
  example two clicks in one tick. Say why in a comment.

## Waiting

- Wait for a state, never for a fixed time or for network idle. Do not use
  `waitForTimeout` or `networkidle`.
- With `@playwright/test`, use a web-first assertion such as
  `await expect(locator).toHaveText("Saved")`. It retries until the state
  appears.
- Do not read a value once and then assert it, as in
  `expect(await locator.isVisible()).toBe(true)`. It does not retry.
- With `playwright-core`, wait with `locator.waitFor()` or
  `page.waitForFunction()` before you read a value.
- Await every Playwright call.
- Control time with the Playwright clock. Install it before the page reads
  the time.

## Isolation and data

- Give each test its own browser context, page, and data. Close the page in
  a `finally` block or a fixture.
- Seed unique data for each test through the app's API or the repository's
  test harness. Do not depend on shared data or on test order.
- Route only third-party traffic with `page.route`. In an end-to-end test,
  do not stub your own backend. In a harness test, control the backend
  through the harness.

## Accessibility

- When the repository runs `@axe-core/playwright`, do not disable a rule to
  make a check pass.

## Failures

- Debug a failure from its trace, screenshot, or video. Do not rerun until
  it passes.
- A retry in the runner configuration is not a fix. A test that passes only
  on a retry is flaky. Follow
  [deterministic-tests.md](deterministic-tests.md).
- Screenshot baselines follow [snapshots.md](snapshots.md).

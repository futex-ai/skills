# Snapshots

A snapshot is an expected value that a tool records for you. Text
snapshots include `insta` files and Jest or Vitest snapshots. Image
snapshots include Playwright screenshot baselines. ARIA snapshots record the
accessibility tree.

## When to snapshot

- Snapshot large, readable, structured output: command output, rendered
  text, or a serialized response. Prefer YAML or JSON of a serializable
  value.
- Use a precise assertion, not a snapshot, for critical logic and for simple
  values such as one number or one string.
- Keep each snapshot small. Snapshot the part of the output that the test
  name describes.
- Name each snapshot. With `insta`, add a description or info so that a
  reviewer can judge the value without the test source.
- Redact timestamps, generated IDs, random values, and absolute paths. The
  `insta` redactions and Playwright regular expressions do this.

## Review a change

- Run the tests once and read each new value. With `insta`, read each
  `.snap.new` file in `cargo insta review` and accept or reject it on its
  own.
- Accept a change only when your task intends it. If you did not expect the
  change, treat it as a failed test. Find the root cause first.
- Run a bulk update only on the tests whose diffs you read. Bulk updates are
  `cargo insta accept`, `INSTA_UPDATE=always`, `-u`, `--updateSnapshot`,
  and `--update-snapshots`. Never run one to make a red suite green.
- In the final report, list each accepted change and say why the new value
  is right.
- Delete an obsolete snapshot file on purpose, and name it in the report.
  `cargo insta test --unreferenced=reject` lists the stale `insta` files.
- CI never writes snapshots. The default `INSTA_UPDATE=auto` and the Jest
  and Vitest CI modes already fail on a missing or changed snapshot. Do not
  change that.

## Screenshot baselines

- Use a screenshot only where the layout is the behaviour. Use an ARIA
  snapshot or a text assertion for structure and content.
- Make baselines in the same environment as CI. Fonts and rendering differ
  between machines.
- Look at each diff image before you update a baseline. Update only the
  baselines of the tests that you reviewed, with a test filter.
- Name each updated baseline in the report.

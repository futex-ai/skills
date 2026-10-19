---
name: product-ui
description: Use before you implement or change a screen, a component, a view, or a mockup, when you write or edit user-facing text such as a status, helper, label, or error message, when you add an empty, loading, or error state, when you are about to hardcode a number, a row, or sample data in a screen, when you add an accent border, a badge, or an environment label, and when you need a component that may already exist.
---

# Product UI

Where screens live and which shared UI library to check first is in the
repository's `AGENTS.md` under `## Product`.

## Component reuse

- Before you build UI, check the shared UI library named in `AGENTS.md`
  first, then the app's reusable base components. Use them where possible.
- If a component or pattern is used many times across the app, extract it
  or add it to the shared components instead of duplicating the
  implementation.

## Forbidden visual patterns

- Never use a left-edge accent border or vertical accent rail to emphasize,
  select, categorize, decorate, or communicate the status of content. This
  includes a contrasting stroke attached to the left side of a card, panel,
  callout, banner, toast, quote, list row, navigation item, or any other
  content surface, including strokes with rounded ends or corners.
- Do not recreate the pattern with a pseudo-element, inset shadow,
  gradient, outline, or separate adjacent bar.
- Use the component system's typography, spacing, icons, full-surface
  treatments (a full-perimeter border, a tinted fill, a leading icon), or
  standard selection controls instead.
- Neutral structural borders such as column dividers and nesting indent
  guides are layout, not emphasis, and remain fine.
- This applies to product code and to mockups.

## Environments

Normal product views do not expose sandbox, test, or preview environment
labels, badges, or explanatory copy. The same view renders across
environments, with environment-specific data selected from the URL or the
environment configuration.

## Real data only

- Dynamic user, business, and domain data displayed to the user is never
  faked, stubbed, hardcoded, or mocked in product code. Metrics, entities,
  statuses, rows, and calculated values come from a real source: an API, a
  database, a store, or live computation.
- Do not ship placeholder numbers, dummy rows, lorem-ipsum content, or
  "TODO: wire up real data" values in screens users can reach.
- Static product copy, navigation labels, accessibility text, form
  placeholders, design constants, and explicit loading, empty, error, or
  unavailable-data states are not dynamic data and may live in product
  code.
- If the real source is not available yet, render an explicit unavailable,
  empty, loading, or error state, and wire the view to the real source
  before the feature is complete.
- Faked or stubbed data is acceptable only in tests, mocks, fixtures, and
  mockups.

## Copy

- User-facing copy reads as product language written for the user, not as
  engineer-facing build or status output.
- Lead with the outcome or action the user cares about. Keep it plain and
  professional.
- Keep copy to the minimum that the user needs to understand the outcome,
  decide, or act. Prefer one short sentence for routine status and helper
  text.
- For an error, name what failed and give one recovery action when one
  exists.
- Remove any sentence whose absence would not change what the user
  understands, decides, or does next.
- Never leak internal implementation detail into text users read:
  validation-artefact, schema, or pipeline names, internal flags, message
  classes, file formats, environment names, or code identifiers.
- When technical detail has genuine product value, surface it in a clearly
  secondary place such as a details or profile panel, not in headline copy.
- Keep a positive frame. Say what the product does, where it is, and what
  the reader can do. Answer a question with the positive fact, not with
  "No". State a real limit only when the reader needs it, pair it with
  what they can do instead, and keep it out of headlines.
- This applies to mockups and to product implementation alike.

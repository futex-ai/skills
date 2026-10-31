---
name: mockups
description: Use before you create or change a mockup under docs/mockups, a screen component, a user flow, or a Mokly entry, component, or configuration, when a plan has a mockup milestone or a feature needs a new screen, when a page needs more than five screens, when a user flow needs a screen that does not exist, when the code or a protocol doc does not match a mockup, and when generated mockup output looks wrong or is about to be edited or committed.
---

# Mockups

Mockups are part of the spec and stay aligned with the implementation at
all times. The forbidden visual patterns and copy rules in the `product-ui`
skill apply to mockups too.

## Design before implementation

- Any work that needs design implementation updates an existing mockup or
  creates a new one first, before the implementation lands. In a plan, the
  mockup milestone is Milestone 1. It comes before every other milestone,
  also before the documentation milestone. See the `plans` skill.
- Consider where each screen sits in the wider app. Do not build an
  isolated mockup that cannot be reached from another relevant screen,
  flow, or navigation surface. Keep new mockups visually and structurally
  consistent with existing screens.

## Variants and pages

- Every mockup includes two variants: a mobile variant and a web or desktop
  variant.
- A generated screen-spec page renders no more than five screen mockups. If
  a product area needs more states, screens, or flows, split it into linked
  nested sub-pages instead of adding a sixth mockup. User-flow sequence
  pages are exempt because they reuse screens from the owning screen-spec
  pages.
- A non-terminal page (one with child pages) renders one canonical "best
  representation" screen, then lists links to its child sub-pages. Put each
  child page in its own matching directory so that the generated output and
  the page source tree mirror the visible page hierarchy. Pure gallery or
  catalogue index pages are exempt from the canonical-screen requirement.
- Mockup screens contain no implementation hints, engineering notes, or
  explanatory annotations inside the rendered screen area. Put hints below
  the screen or in a separate non-screen section.

## Screen components and user flows

- Each app screen is its own component: one screen, one component, for
  both the mobile and the web variant. Screen components are the reusable
  building blocks that user flows compose. Do not inline a screen's markup
  into a flow.
- A user flow shows a sequence of screens across a scenario, not a single
  standalone screen.
- User flows use only existing screen components, and each screen in a flow
  links back to its original standalone screen mockup. If a flow needs a
  screen that does not exist, first add the screen component to the owning
  screen-spec page so that it renders standalone there, then import it into
  the flow. A user flow is never the original home of a screen.

## Mokly-generated output

- The mockup catalogue is generated from entry modules (`*.mockup.ts` or
  `*.mockup.tsx`) and shared TSX components by the Mokly configuration.
  Definitions and helpers compose TSX components, not large raw HTML
  strings or generated static-tree data.
- Do not hand-edit generated HTML or the generated manifest as a source of
  truth. Update the entry, helper, renderer, or shared component first,
  then regenerate.
- Never commit the generated directory. Commit authored files normally:
  specs, configuration, CSS, and components.
- After changing entries, the renderer, configuration, or styles, rebuild,
  run the mockup check command named in `AGENTS.md`, and visually
  smoke-test the changed pages.

## When a protocol doc, a mockup, and the code disagree

The protocol doc wins over the mockup, and the mockup wins over the code.
When two of them disagree, change the lower side to match the higher side.

- A recorded user decision comes first. It can be in the task message,
  the approved plan, or a follow-up item. Update the higher sides to match
  it in the same change. In a plan, the mockup milestone changes the
  mockups, and the documentation milestone then updates the protocol docs.
- When a difference between a mockup and the code is new in the branch,
  and no recorded user decision covers it, the code has a product bug.
  Fix the code.
- When a mockup differs from a protocol doc, and no recorded user
  decision covers the difference, the mockup is wrong. Fix the mockup.
- When a mockup and the code already differ on `origin/main`, and no
  protocol doc settles the difference, ask the user. There the mockup can
  be the stale side.
- When the higher side is wrong, or worse than the lower side, propose its
  change to the user as a decision, as the `documentation` skill says.
- Sample data in a mockup is not a requirement. The product shows real
  data, as the `product-ui` skill says.
- When a mockup breaks a rule of the `product-ui` skill, the mockup is
  wrong. Fix the mockup.

# Example: one finding before and after the layout

The finding comes from a review of the docs for a mockup viewer. The file
path and line are examples.

## Before: long prose

Do not write this. The fields are in one paragraph. Severity, effort,
category, location, and the Auto-fix line are missing. The options are not
in a list, and the recommendation gives no reason. Five sentences have more
than 25 words, and three use semicolons.

> 1. Where the viewer finds a component instance inside a page. A rendered
> screen contains components. The viewer has a "pick" feature: a reader
> clicks an element in the rendered page, and the viewer highlights the
> component instance that owns that element and names it in the side
> panel. Today the bounds of each instance are HTML comments written around
> it. A recent decision says the comments exist only in the renderer's
> output; the server reads them, records the bounds on its internal tree,
> and writes the final page without them. With no comments and no other
> mark, the inspector script has nothing to search for. Option (a) keeps
> the comments in the served pages and removes them only in the comparison
> step, so the comparison sees clean trees and the inspector sees the
> comments. Option (b) adds a data attribute to each instance's root
> element instead; this is simpler for the inspector but an attribute can
> match a user's CSS selector and change the look of the mockup. Option (c)
> sends the element's position in the detail JSON; this breaks as soon as
> the page's DOM differs from the server's tree, which happens when a
> script runs. I recommend (a).

## After: the finding layout

```markdown
### 1. The inspector cannot find component instances

- **Severity:** High. **Effort:** Medium.
- **Category:** Docs or spec.
- **Location:** `docs/protocol/viewer-pick.md:40`.
- **Context:** The viewer has a pick feature. A reader clicks an element in a rendered page. The viewer then highlights the component instance that owns the element. A script in the page, the inspector, finds each instance by the HTML comments around it. A recent decision removes these comments from the final page, but the viewer docs still expect them.
- **Impact if no action:** Pick and highlight cannot work. The inspector has nothing to search for.
- **Options:**
  - **A.** Keep the comments in served pages. Remove them only in the comparison step.
  - **B.** Add a data attribute to the root element of each instance. A user's CSS selector can match it and change the mockup.
  - **C.** Send the position of each element in the detail JSON. The position is wrong after a script changes the page.
  - **D.** Wider fix: add a test that fails when a served page has no instance marks.
- **Recommendation:** A. The inspector keeps a mark to search for, and the comparison still gets clean trees.
- **Auto-fix:** no, because the options have real trade-offs.
```

## What changed

- Each field has a label, so a missing field is easy to see.
- Each option is on its own line.
- The recommendation gives one sentence of reasoning.
- No sentence has more than 25 words, and no sentence uses a semicolon.

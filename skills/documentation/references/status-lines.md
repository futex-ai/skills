# Status lines

A doc can describe behaviour before the code has it. The documentation
milestone of a plan writes the requirements before the code. Part of the
behaviour can also wait in a follow-up item after the merge. A status
line tells the reader which behaviour is not built yet, and which work
will build it.

## The shape

The status line comes directly below the title of the doc:

```markdown
Status: Not built yet: <the missing behaviour>. See the [<plan or item>](<link>).
```

- Name each part of the doc that is not built, in a few words. When no
  part is built, write "every requirement on this page".
- Link the active plan or the follow-up item that will build each part.
  When two items build two parts, name both parts and link both items.
- A doc has at most one status line.
- Give no date, approval, branch, or history. The plan and the pull
  request hold them.
- The doc has no other link to that plan or item, so that one edit
  removes the link.
- A doc whose behaviour is built has no status line. Do not write
  "Status: current" or "Status: implemented".

Example, from a protocol doc whose lint waits in a follow-up item:

```markdown
Status: Not built yet: the lint for three more clock forms in tests. See the [viewer clock lint item](../../plans/follow-ups/viewer-clock-lint.md).
```

## When to add it

Add a status line when a doc reaches `main` before its behaviour:

- A pull request merges the docs of a plan, and a later pull request of
  that plan builds the behaviour.
- A change leaves behaviour that a doc states to a follow-up item.

A branch whose pull request builds all the behaviour that its docs
describe needs no status line.

## When to change or remove it

- Remove the status line in the change that builds its behaviour. When
  the change builds only one part, remove that part from the line.
- A status line is stale when the code has the behaviour that it names.
  It is also stale when the plan or the item that it links is gone. Fix
  it in the same change, as for every stale doc.
- Before you delete a plan, remove each status line that links the plan
  and whose behaviour is built. Link each other line to the follow-up
  item that will build the rest. Add that item when none exists.
- The branch that fixes a follow-up item removes each status line that
  links the item.
- A drop of a follow-up item is the user's decision not to build its
  behaviour. In the same branch, remove that behaviour from the status
  line and its requirements from the doc. Name each removed requirement
  in the commit message.

## Docs that ship with a release

A doc that ships to users with a release describes built behaviour only.
It has no status line, because its readers cannot open `plans/`.
Examples are the README of a published package and the guides in a
package. The repository's `AGENTS.md` names these docs when the package
manifest does not show them.

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

## Keep the line true

A true status line names each part of the doc that is not built. Each
part links the active plan or follow-up item that will build it. When no
part remains, the line goes. Check the line at each of these events:

- A change builds a part. Remove that part and its link.
- The user drops a follow-up item. A drop is the user's decision not to
  build its part. Remove the part from the line and its requirements
  from the doc. Name each removed requirement in the commit message.
- A plan or a follow-up item is deleted for another reason while its
  part is not built. Link the part to the follow-up item that will build
  it. Add that item when none exists.

A status line is stale when it names a part that the code has. It is also
stale when it links a plan or an item that is gone. Fix it in the same
change, as for every stale doc.

## Docs that ship with a release

A doc that ships to users with a release describes built behaviour only.
It has no status line, because its readers cannot open `plans/`.
Examples are the README of a published package and the guides in a
package. The repository's `AGENTS.md` names these docs when the package
manifest does not show them.

---
name: findings
description: Use when the user types /findings, or asks to see, list, or reprint the open items, the findings, or the decisions of this conversation, as in "what is still open?" or "reprint the findings", or asks to see given item numbers again.
---

# Findings

This skill re-prints the items of this conversation in the layout of the
`decisions-and-findings` skill, with every update applied. A later
message gives an unchanged open item in one line only, as the "Open
items" section of that skill says. This skill gives the full text when
the user asks for it.

## What to print

- An open item waits for the user's answer. A closed item has an outcome:
  the user answered it, an agent fixed it, it waits in a follow-up item,
  or the user dropped it.
- When the user names no items, give every open item in full and one line
  for each closed item.
- When the user names item numbers, give only those items in full. Under
  the title of a closed item, one sentence gives its outcome.

## Steps

1. Read the records first. A context summary can drop the text of an
   earlier item, but the records keep it. The records are:
   - the findings file of the branch, at the path that the
     `implementation-review` skill gives,
   - the plan of the change, with its decisions, and the follow-up items
     that the change added,
   - the brainstorm notes under `.context/`.
2. Add each item of this conversation that the records do not hold.
3. Apply each update in the order that it happened: the user's answers,
   the fix commits, the follow-up items, and each changed field.
4. Check each open item against the current code. Update each field that
   the code changed.
5. Write each item with the rules in the "Explaining items again" section
   of the `decisions-and-findings` skill. Keep the recorded numbers and
   option letters.
6. Find each open item that changed since the last message that gave it
   in full. Under its title, write one sentence that says what changed.

## The message

Use the message order of the `decisions-and-findings` skill:

1. When an item is open, start with the warning line that the "Open
   items" section gives. When no item is open, the first sentence says
   so.
2. Add the background paragraph and the shared **Terms**. The reader may
   not remember the earlier messages.
3. Give the open items in full under `## Needs your answer`, in the item
   order.
4. End with the final report. It lists every closed item of this
   conversation:
   - **Changed:** nothing changed, because this message only re-prints.
   - **Fixed**, **Deferred**, and **Decisions:** one line for each closed
     item, under the label of its outcome. A dropped item goes under
     **Decisions**.
   - **Checks:** the records that you read, and each item that you could
     not rebuild from them.
   - **Open:** one line for each open item. A `fix now` finding without a
     commit goes here too, as work in progress.

## Checklist

- [ ] The records were read before the items were written.
- [ ] Every item of this conversation is in the message: the open items
      in full, the closed items in one line each.
- [ ] The recorded numbers and option letters are kept.
- [ ] Each open item was checked against the current code.
- [ ] Each changed item has one sentence that says what changed.
- [ ] The warning line at the top names the open items.

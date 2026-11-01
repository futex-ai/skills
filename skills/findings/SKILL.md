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

- An open item waits for the user's answer, as the "Open items" section
  defines it. Every other item of this conversation is closed. Its
  recorded outcome gives its label in the final report.
- A call without item numbers asks for every open item. A call with item
  numbers asks for the named items only.
- The "Open items" rules give an open item in full when it is new,
  changed, or asked for. They give every other open item one line under
  **Open**.
- Give each closed item that the call names in full, in the item order.
  Under its title, one sentence gives its outcome.

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
   the fix commits, the deferrals with their follow-up items, and each
   changed field.
4. Check each open item against the current code. Update each field that
   the code changed.
5. Find each open item that changed since the last message that gave it
   in full. The "Open items" section says what counts as a change.
6. Write each item with the rules in the "Explaining items again" section
   of the `decisions-and-findings` skill. Keep the recorded numbers and
   option letters.

## The message

Use the message order and the "Open items" rules of the
`decisions-and-findings` skill. When no item is open, the first sentence
says so. The final report holds these lines:

- **Changed:** nothing changed, because this message only re-prints.
- **Fixed**, **Deferred**, and **Decisions:** for a call without item
  numbers, one line for each closed item, under the label of its
  recorded outcome. A dropped item and each design call go under
  **Decisions**.
- **Checks:** the records that you read, each item that you could not
  rebuild from them, and each finding that a check removed.
- **Open:** one line for each open item, as the "Final report" section
  says. A `fix now` finding without a commit goes here too, as work in
  progress.

## Checklist

- [ ] The records were read before the items were written.
- [ ] The message follows the "Open items" rules. Each closed item that
      the call names is in full, with its outcome.
- [ ] For a call without item numbers, each closed item has one line
      under the label of its outcome.
- [ ] The recorded numbers and option letters are kept.
- [ ] Each open item was checked against the current code.

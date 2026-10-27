---
name: decisions-and-findings
description: Use before you send a message that asks the user for a decision, presents review findings or review items, or gives a final report, when the user asks for more detail, a shorter answer, or an explanation of earlier decisions or findings, when you list open findings from a plan, a saved review report, or an earlier message, when you order or number the decisions and the findings of a message, and when an output style asks for brevity while you write such a message.
---

# Decisions and findings

Use this skill for each message that asks for a decision, presents review
findings, or gives a final report. The reader may have no context. The
reader must act on each item. A fixed layout lets the reader find each
field and answer by number and letter.

## Precedence

These rules are specific rules. They apply also when an output style or a
system prompt asks for brevity or plain prose. The layout is real
structure, not decoration. Brevity means fewer words. It does not mean
fewer items, fewer fields, or longer sentences. An instruction not to
restate the plan or to recap earlier messages does not apply to the items.

A skill or a prompt for one task can set its own message order. Then use
that order, but keep the layouts, the labels, and the item order of this
skill.

## Simplified Technical English

Write in Simplified Technical English (ASD-STE100):

- Use a maximum of 20 words in an instruction.
- Use a maximum of 25 words in a description.
- Write one instruction or one fact in each sentence.
- Use the active voice.
- Use a maximum of six sentences in a paragraph.
- Do not use semicolons. Do not put a clause or a list in parentheses.
- Use a vertical list for steps, options, and complex lists.
- Use one word for one thing. Define each project term once, then use it
  the same way.
- To give more detail, add sentences or list items. Do not make a sentence
  longer.

## Message order

1. Start with one or two sentences that give the result or the question.
2. When the items share background, add a background paragraph. Say what
   the project is, what the feature does, and what changed. Use six
   sentences or fewer. The **Background** of each item then adds only what
   that item needs.
3. When two or more items use the same term, add a shared **Terms** list
   after the background paragraph. The **Terms** of each item then adds
   only the terms that no other item uses.
4. With more than five items, add a summary table. Give the number, the
   title, the severity, the effort, and the recommended option. Use the
   same order as the items.
5. Give each item in the layout below.
6. When the task ends, finish with the final report.

## Item order

Keep the decisions and the review findings in two separate lists, each
under its own heading. In each list, order the items by severity: High
first, then Medium, then Low. Keep the relative order of items with the
same severity. Put the review findings first and the decisions second.
Number the items once across the whole message, in that order. The summary
table and the final report keep the same lists and the same order.

## The complete list

A message with decisions, findings, or a final report gives every open
item. The user must not need an earlier message to act.

- An open item is a decision or a finding that has no answer from the
  user and no fix.
- Give every open item in its full layout. This includes an item from an
  earlier message, an earlier review round, the plan, or a review report.
  It also includes an item that did not change.
- Give each item its own number, heading, and layout. Do not merge items
  under one heading or into a range, such as "4 to 7".
- Do not replace an item, a field, or an option with a pointer. A pointer
  sends the user to an earlier message, the plan, or a report.
- Use the rules in **Repeating items** below to rebuild an item from an
  earlier record.

| The excuse | The answer |
| --- | --- |
| "Findings 3 to 6 of the first review, unchanged." | An unchanged item is still open. The user needs it in this message to answer it. |
| "I gave their full layout in my message of this morning" | The user does not go back through old messages. Give the full layout again. |
| "the plan records them with the recommended options" | The plan has one line for each item. The user needs every field to decide. |

Red flags:

- You write "unchanged", "stays open", "as before", "as recorded", or "my
  earlier message" about an item that has no layout in this message.
- A heading holds a range of numbers, such as "4 to 7".
- The summary table has more rows than the message has item layouts.

A short summary under the heading of each item keeps the numbers and
loses the layout. It breaks this rule.

## Decision layout

Use this layout for each decision that is not a review finding.

```markdown
### 1. <The problem, in eight words or fewer>

- **Severity:** <High, Medium, or Low>. **Effort:** <Small, Medium, or Large: the grade of the recommended option.>
- **Terms:** <Only when the item uses a term that the shared list does not define. Up to five entries.>
  - **<Term>:** <One sentence: what it is, and where it lives when that helps the reader find it.>
- **Background:** <Two to five sentences: what the feature does and where it is. Use plain words and defined terms only.>
- **Problem:** <One to three sentences that say what is wrong. Use plain words and defined terms only.>
- **Impact if no action:** <One or two sentences.>
- **Options:**
  - **A.** <The change.> <Its cost or risk.> Effort: <Small, Medium, or Large>.
  - **B.** <The change.> <Its cost or risk.> Effort: <Small, Medium, or Large>.
  - <More options as C, D, and so on, when the problem has them.>
- **Recommendation:** <Letter>. <One sentence of reasoning.>
- **Auto-fix:** no, because <the reason that you cannot choose alone.>
```

## Finding layout

Use this layout for each review finding, also when it needs a decision. A
review item is a review finding. The `implementation-review` skill says
what each field must contain.

```markdown
### 1. <The problem, in eight words or fewer>

- **Severity:** <High, Medium, or Low>. **Effort:** <Small, Medium, or Large: the grade of the recommended option.>
- **Category:** <One category from the scales below.>
- **Location:** <The file path and line.>
- **Terms:** <Only when the item uses a term that the shared list does not define. Up to five entries.>
  - **<Term>:** <One sentence: what it is, and where it lives when that helps the reader find it.>
- **Background:** <Two to five sentences: what the feature does and where it is. Use plain words and defined terms only.>
- **Problem:** <One to three sentences that say what is wrong. Use plain words and defined terms only.>
- **Impact if no action:** <One or two sentences.>
- **Options:**
  - **A.** <A fix.> <Its cost or risk.> Effort: <Small, Medium, or Large>.
  - **B.** <Another fix.> <Its cost or risk.> Effort: <Small, Medium, or Large>.
  - <More options as C, D, and so on, when the problem has them.>
- **Wider fix:** <The letter of the option that prevents this class of issue. A structural fix, such as a helper, an abstraction, a marker, a default, or a type, ranks above a detection fix, such as a test for the class, a lint, or a guard. Or "None" and the reason, for example that the wider fix is already in force.>
- **Previous examples:** <Earlier cases of this class, with commits or files, or "None found". Also the other findings in this review that share the wider fix.>
- **Recommendation:** <Letter>. <One sentence of reasoning.> <When another option best protects the codebase, one sentence that names it.>
- **Auto-fix:** <`yes, apply` and the letter of the option to apply, or `no, because` and the condition that stops the fix.>
```

Give one lettered option for each real choice. Order the options from the
smallest effort to the largest, and give each its own grade. The wider
fix is one of these options.

A problem outside the review scope is not a finding. The
`implementation-review` skill gives its one-line shape. The final report
lists it under **Open**, for a separate branch.

In both layouts, keep every label, also when the user asks for more detail
or for a shorter answer. An item leaves out **Terms** only under the rule
below. For more detail, write **Background** as a list with one fact in
each item.

## Terms

A term is a name from the codebase, the product, or the toolchain that an
engineer new to the repository would look up. A general programming word
is not a term. When an item uses a term that the shared list does not
define, add **Terms** before **Background**. Define the term there.
Otherwise leave **Terms** out.

Each entry is one sentence of 25 words or fewer. Say what the thing is.
Add where it lives when that helps the reader find it.

A **Terms** list holds at most five entries. When an item needs more,
first check that the shared list holds each term that two or more items
use. Then write the item in plainer words. When the shared list needs
more, write the items in plainer words. The shared list uses the same
entry shape under a **Terms** heading.

## Scales

- Severity. High: wrong output, lost data, a security problem, or blocked
  work. Medium: a visible defect, or a spec gap with a workaround. Low:
  wording, style, or a rare edge case.
- Category. Product bug, security, docs or spec, mockup, repository rule,
  test, performance, code structure, dead code, UX wording, or process.
- Effort. The grade of one option, not of the problem. Count the code
  change only: product code, scripts, configuration, and infrastructure
  files. Do not count tests, README files, protocol docs, plans, or mockup
  output, because the repository rules require them with each code change.
  Small: two code files or fewer, 30 code lines or fewer, and no new code
  or test file. Medium: five code files or fewer in one package, and 150
  code lines or fewer. A new test file or a new helper module in the same
  package is Medium. Large: every option that is not Small or Medium. A
  new dependency, a migration, a change on both sides of the backend and
  frontend boundary, a new mockup, or a new protocol section is Large
  whatever its size. The effort of an item is the grade of its
  recommended option.

## Repeating items

These rules apply to each item that an earlier message, the plan, or a
review report gave. They apply when you list an open item again, and when
the user asks you to explain an item again.

- Read the saved review report first, when it exists.
- Check the item against the current code. Update each field that changed.
- Restate every field. Do not point to an earlier message for a field.
- Keep the recorded option letters of each item and their order, also
  when an effort grade changed.
- When the record gives no wider fix, look for one. Add the wider fix that
  you find as a new option with the next free letter.
- The recorded number of an item is its number in the last message that
  showed it to the user. Keep that number.
- When two items have the same recorded number, the item that the user
  saw first keeps it.
- Give a new number to the other item and to each item that the user did
  not see. A new number is one above the highest number that the user
  saw. Never reuse a number, also not the number of an answered item.
- When a new number differs from the number in the record, add a
  **Source:** line under the title. Name the record and the old number.
- List the items by severity, also when the recorded numbers are then out
  of sequence. Do not renumber them for this.
- Always write **Background**, **Problem**, **Impact if no action**, and
  **Options**. They explain the item, so you can write them from the
  record, the code, and the docs.
- Add **Terms** under the rule above, also when the record has none. You
  can write it from the code and the docs.
- Some fields are judgments: severity, effort, category, recommendation,
  and Auto-fix. When the record does not give a judgment, give your own.
  Add "(estimate)" after it.
- When you cannot find the location, write "Not found". When you find no
  previous examples, write "None found".

## Final report

End every task with a final report. Under **Fixed** and under **Open**,
keep the item order above. Use these labels:

- **Changed:** what changed, the commit, and the branch or the pull
  request.
- **Fixed:** each auto-fixed finding. Give its number, its severity, a
  plain explanation, the applied option, what changed, and the commit.
- **Decisions:** each decision that the user answered, one line each. Give
  the number, the chosen letter, what that option does, and the outcome.
- **Checks:** each check and its result. Give the output of a failed
  check. Name each check that was skipped or blocked, and give the reason.
  Name each unrelated flaky test with its failure text, rerun outcome, and
  suspected source.
- **Open:** list each of these entries, also when an earlier message gave
  it:
  - The decisions and review items that still need the user. For each
    open decision, say what it blocks.
  - The open plan TODOs and the follow-ups. A follow-up for a wider fix
    that the review did not apply is one line per class. The line gives
    the wider fix, its effort, the finding numbers it covers, and the
    previous examples.
  - The problems outside the review scope, for a separate branch.
  - Other skipped or blocked work.

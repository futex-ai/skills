---
name: decisions-and-findings
description: Use before you send a message that asks the user for a decision, presents review findings or items, or gives a final report, before you raise a question as a decision, when you write the options of a decision or a finding, when the user asks for more detail, a shorter answer, or an explanation of earlier decisions or findings, when you list open findings from a plan or a review report, when you order or number the decisions and findings of a message, and when an output style asks for brevity.
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
fewer fields or longer sentences.

A skill or a prompt for one task can set its own message order. Then use
that order, but keep the layouts, the labels, and the item order of this
skill.

## The decision test

Apply this test to each question before you write it as a decision. Look
at the option that you recommend. The question is a decision for the
user only when one of these conditions holds:

1. The recommended option changes a requirement or a decision in force.
2. The recommended option adds behaviour at a boundary that no
   requirement covers.
3. The recommended option is blocked under the review-fix rule in the
   `implementation-review` skill. It is Large, deletes functionality,
   adds a gate or stricter validation, weakens a test, or needs
   credentials or infrastructure.
4. Two or more options have real trade-offs, and no option is clearly
   best.
5. The user asked you to bring this choice to them.

A detail that an existing requirement settles is not a gap, also when the
requirement does not spell the detail out. An option that drops the
requirement does not make the question a decision when you do not
recommend that option.

When no condition holds, the question is a design call. Apply the
recommended option. Record the call, its reason, and the date in the
plan, in the design of the change. When the change has no plan, record
it in the commit or the pull request description. Do not ask the user.
Give each design call one line in the final report.

Three signs that a question fails the test:

- The recommendation says that the option costs nothing.
- The severity is Low, and the impact is only that the work waits for the
  answer.
- The **Action** reason says only that the item is a decision.

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

## Decision layout

Use this layout for each question that passes the decision test and is
not a review finding.

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
- **Action:** ask the user, because <the number of the condition of the decision test that holds, and one sentence of evidence.>
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
- **Action:** <`fix now, apply` and a letter. Or `fix after merge, apply` and a letter, with one sentence of reason. Or a split: `fix now, apply` the direct fix, `and fix after merge, apply` the wider fix, with one sentence of reason. Or `ask the user, because` and the condition that sends the item to the user.>
```

A problem outside the review scope is not a finding. The
`implementation-review` skill gives its one-line shape. The final report
lists it under **Open**, for a separate branch.

In both layouts, keep every label, also when the user asks for more detail
or for a shorter answer. An item leaves out **Terms** only under the rule
below. For more detail, write **Background** as a list with one fact in
each item.

## Options

Give one lettered option for each real choice. Order the options from the
smallest effort to the largest, and give each its own grade. When you
explain an item again, keep the recorded letters and their order. The
wider fix of a finding is one of these options.

Before you write the options, ask two questions. Are these the only
options? What would you build if the current code did not exist? Add each
new option that the questions give.

For a decision, then name each condition that every option keeps. Name
its source: a protocol doc, a user decision, the task message, an earlier
option's text, or the code. When it is not a requirement, or its reason
is gone, add the option that drops it. A user decision covers the choice
that the user made, not each sentence of the text that describes the
chosen option. For a finding, the options check of the
`implementation-review` skill asks this in a fresh context.

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

## Explaining items again

- Read the saved review report first, when it exists.
- Restate every field. Do not point to an earlier message for a field.
- Keep the recorded option letters of each item.
- When the record gives no wider fix, look for one. Add the wider fix that
  you find as a new option with the next free letter.
- Keep the recorded number when no other item in the message has it.
  Otherwise, give the next free number. Then add a **Source:** line under
  the title with the record and the old number.
- List the items by severity, also when the recorded numbers are then out
  of sequence. Do not renumber them for this.
- Always write **Background**, **Problem**, **Impact if no action**, and
  **Options**. They explain the item, so you can write them from the
  record, the code, and the docs.
- Add **Terms** under the rule above, also when the record has none. You
  can write it from the code and the docs.
- Some fields are judgments: severity, effort, category, recommendation,
  and Action. When the record does not give a judgment, give your own.
  Add "(estimate)" after it.
- When you cannot find the location, write "Not found". When you find no
  previous examples, write "None found".

## Final report

End every task with a final report. Under **Fixed**, **Deferred**, and
**Open**, keep the item order above. Use these labels:

- **Changed:** what changed, the commit, and the branch or the pull
  request.
- **Fixed:** each finding that the agent fixed. Give its number, its
  severity, a plain explanation, the applied option, what changed, and the
  commit.
- **Deferred:** each finding or wider fix with `fix after merge`. Give the
  finding number, its severity, the reason, and the follow-up item. When
  the repository has a `plans/` directory, give the number of open
  follow-up items. The `plans` skill gives the script that counts them.
- **Decisions:** each decision that the user answered, and its outcome.
  Then each design call that you made under the decision test, in one
  line: the call and its reason.
- **Checks:** each check and its result. Give the output of a failed
  check. Name each check that was skipped or blocked, and give the reason.
  Name each unrelated flaky test with its failure text, rerun outcome, and
  suspected source.
- **Open:** the decisions and review items that still need the user. For
  each open decision, say what it blocks. Add the open plan TODOs. Add the
  follow-up items of the blocked wider fixes and of the problems outside
  the review scope, and other skipped or blocked work. A blocked wider fix
  is one line per class. The line gives the wider fix, its effort, the
  finding numbers it covers, and the previous examples.

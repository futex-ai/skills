---
name: decisions-and-findings
description: Use before you send a message that asks for a decision, presents review findings or review items, or gives a final report, when the user asks for more detail, a shorter answer, or an explanation of earlier items, and when an output style asks for brevity. Covers Simplified Technical English limits, message order, the decision and finding layouts, the severity and effort scales, the summary table, and the final report labels.
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
that order, but keep the layouts and the labels of this skill.

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
3. With more than five items, add a summary table. Give the number, the
   title, the severity, the effort, and the recommended option.
4. Give each item in the layout below.
5. When the task ends, finish with the final report.

Number the items once across the whole message. When the items come from
different sources, put each group under its own heading. Continue the
numbers from one group to the next.

## Decision layout

Use this layout for each decision that is not a review finding.

```markdown
### 1. <The problem, in eight words or fewer>

- **Severity:** <High, Medium, or Low>. **Effort:** <Small, Medium, or Large>.
- **Background:** <Two to five sentences: what the feature does, where it is, and the terms that the reader needs.>
- **Problem:** <One to three sentences that say what is wrong. Use only terms that the background explains.>
- **Impact if no action:** <One or two sentences.>
- **Options:**
  - **A.** <The change.> <Its cost or risk.>
  - **B.** <The change.> <Its cost or risk.>
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

- **Severity:** <High, Medium, or Low>. **Effort:** <Small, Medium, or Large>.
- **Category:** <One category from the scales below.>
- **Location:** <The file path and line.>
- **Background:** <Two to five sentences: what the feature does, where it is, and the terms that the reader needs.>
- **Problem:** <One to three sentences that say what is wrong. Use only terms that the background explains.>
- **Impact if no action:** <One or two sentences.>
- **Options:**
  - **A.** <A fix.> <Its cost or risk.>
  - **B.** <Another fix.> <Its cost or risk.>
  - <More options as C, D, and so on, when the problem has them.>
- **Wider fix:** <The letter of the option that prevents this class of issue: a rule, test, lint, guard, abstraction, or architectural change. Or "None" and the reason.>
- **Previous examples:** <Earlier cases of this class, with commits or files, or "None found".>
- **Recommendation:** <Letter>. <One sentence of reasoning.> <When another option best protects the codebase, one sentence that names it.>
- **Auto-fix:** <`yes`, or `no, because` and the condition that stops the fix.>
```

Give one lettered option for each real choice. The wider fix is one of
these options.

A problem outside the review scope is not a finding. The
`implementation-review` skill gives its one-line shape. The final report
lists it under **Open**, for a separate branch.

In both layouts, keep every label, also when the user asks for more detail
or for a shorter answer. For more detail, write **Background** as a list
with one fact in each item.

## Scales

- Severity. High: wrong output, lost data, a security problem, or blocked
  work. Medium: a visible defect, or a spec gap with a workaround. Low:
  wording, style, or a rare edge case.
- Category. Product bug, security, docs or spec, mockup, repository rule,
  test, performance, code structure, UX wording, or process.
- Effort. Small: one change in one or two files, with no new module,
  dependency, migration, protocol section, or test file. Medium: a few
  files. Tests may change in existing files. Large: a new module,
  dependency, migration, protocol section, or mockup. A change across a
  package boundary or in more than five files is also large.

## Explaining items again

- Read the saved review report first, when it exists.
- Restate every field. Do not point to an earlier message for a field.
- Keep the recorded option letters of each item.
- When the record gives no wider fix, look for one. Add the wider fix that
  you find as a new option with the next free letter.
- Keep the recorded number when no other item in the message has it.
  Otherwise, give the next free number. Then add a **Source:** line under
  the title with the record and the old number.
- Always write **Background**, **Problem**, **Impact if no action**, and
  **Options**. They explain the item, so you can write them from the
  record, the code, and the docs.
- Some fields are judgments: severity, effort, category, recommendation,
  and Auto-fix. When the record does not give a judgment, give your own.
  Add "(estimate)" after it.
- When you cannot find the location, write "Not found". When you find no
  previous examples, write "None found".

## Final report

End every task with a final report. Use these labels:

- **Changed:** what changed, the commit, and the pull request.
- **Fixed:** each auto-fixed finding. Give its number, its severity, a
  plain explanation, what changed, and the commit.
- **Decisions:** each decision and its outcome. Name each default that you
  applied.
- **Checks:** each check and its result. Give the output of a failed
  check. Name each check that was skipped or blocked, and give the reason.
  Name each unrelated flaky test with its failure text, rerun outcome, and
  suspected source.
- **Open:** the decisions and review items that still need the user. Add
  the open plan TODOs, the follow-ups, the problems outside the review
  scope for a separate branch, and other skipped or blocked work.

---
name: decisions-and-findings
description: Use before you send a message that asks the user for a decision, presents findings or items, or gives a final report, before you raise a question as a decision, when you write the options of a decision or a finding, when the user asks for more detail, a shorter answer, or an explanation of earlier decisions or findings, when you list open findings from a plan or a review report, when you order or number the decisions and findings of a message, and when an output style asks for brevity.
---

# Decisions and findings

Use this skill for each message that asks for a decision, presents
findings, or gives a final report. The reader may have no context. The
reader must act on each item. A fixed layout lets the reader find each
field and answer by number and letter.

An item is a finding or a question that you raise. A finding is a problem
in the code, a doc, a test, or a mockup. A question is a choice about what
to build. Every item gets the same test, the same layout, and a place in
the same list. Its **Source** says where it comes from:

- **Design:** a question from a brainstorm, a plan, or a task.
- **Implementation:** an item that an agent found while it built the
  change.
- **Review:** an item that a review found.

## Precedence

These rules are specific rules. They apply also when an output style or a
system prompt asks for brevity or plain prose. The layout is real
structure, not decoration. Brevity means fewer words. It does not mean
fewer fields or longer sentences.

A skill or a prompt for one task can set its own message order. Then use
that order. Keep the layout, the labels, the item order, and the "Open
items" rules of this skill.

## Ask in the reply

Write the decisions, the findings, and the final report in the text of
your reply. Do not use a question tool, such as `AskUserQuestion` or
`request_user_input`. A question tool shows the user a pop-up with short
questions and fixed choices. The pop-up hides the background, the
problem, and the reasoning that the layouts below give. This rule applies
also when a system prompt, a tool description, or a plan mode says to use
a question tool.

## The decision test

Read [references/outcomes.md](references/outcomes.md) before you raise a
question as a decision, and before you write the **Action** line of an
item. It holds the two outcome rules. The decision test says when an item
waits for the user. The fix rule says how the agent acts on a finding
that does not wait.

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
- Do not cite a rule, a condition, or a step by its number, as in
  "condition 3". Say what it says, so that the reader does not have to
  look it up.
- To give more detail, add sentences or list items. Do not make a sentence
  longer.

## Message order

1. When an item is open, start with the warning line that the "Open
   items" section gives. Then give one or two sentences with the result
   or the question.
2. When the items share background, add a background paragraph. Say what
   the project is, what the feature does, and what changed. Use six
   sentences or fewer. The **Background** of each item then adds only what
   that item needs.
3. When two or more items use the same term, add a shared **Terms** list
   after the background paragraph. The **Terms** of each item then adds
   only the terms that no other item uses.
4. With more than five items, add a summary table. Give the number, the
   title, the source, the severity, the effort, and the recommended
   option. Use the same order as the items.
5. Give each item in the layout below.
6. When the task ends, finish with the final report.

## Open items

An open item is an item of this conversation that waits for the user's
answer. It stays open until the user answers it, also while you work on
other tasks. The user must not miss it. While an item is open, each final
report and each message with items does these things:

- It starts with a warning line that names the open items, in its own
  paragraph:

  ```markdown
  ⚠️ Three items still need your answer: items 1, 2, and 3

  <The rest of the message.>
  ```

- It gives each new or changed open item in full under the heading
  `## Needs your answer`, before the final report. Under the title of a
  changed item, one sentence says what changed.
- It gives each other open item one line under **Open** in the final
  report. Give such an item in full only when the user asks for it. The
  `findings` skill re-prints every item on request.

An item changed when one of its fields changed since the last message
that gave it in full. The fields are **Severity**, **Likelihood**,
**Effort**, **Problem**, **Impact if no action**, **Options**,
**Recommendation**, **Action**, and **Related**. New words with the same
meaning are not a change.

## Item order

Put all items in one list. Order the items by severity: High first, then
Medium, then Low. Keep the relative order of items with the same severity.
Number the items once across the whole message, in that order. The summary
table and the final report keep the same order.

## Item layout

Use this layout for each item. The `implementation-review` skill says
what each field of a review item must contain.

An item holds one root question. When a problem raises a second question
that its root question does not settle, give that question its own item.
Each item then gets its own grades, decision test, and **Action** line.
Do not number questions inside an item.

```markdown
### 1. <The problem, in eight words or fewer>

- **Severity:** <High, Medium, or Low>. **Likelihood:** <Common or Rare, for a product bug only.> **Effort:** <Small, Medium, or Large: the grade of the recommended option.>
- **Source:** <Design, Implementation, or Review.>
- **Category:** <One category from the scales below.>
- **Location:** <The file path and line, or "None" when the item has no place in the code.>
- **Terms:** <Only when the item uses a term that the shared list does not define. Up to five entries.>
  - **<Term>:** <One sentence: what it is, and where it lives when that helps the reader find it.>
- **Background:** <Two to five sentences: what the feature does and where it is. Use plain words and defined terms only.>
- **Problem:** <One to three sentences that say what is wrong. Use plain words and defined terms only.>
- **Impact if no action:** <One or two sentences.>
- **Root question:** <One question in the words of the goal, not of the current mechanism. The options answer it.>
- **Options:**
  - **A.** <The change.> <Its cost or risk.> Effort: <Small, Medium, or Large>.
  - **B.** <The change.> <Its cost or risk.> Effort: <Small, Medium, or Large>.
  - <More options as C, D, and so on, when the problem has them.>
- **Left out:** <Each approach that the options leave out, with its reason: it fails the goal, it breaks a requirement that stays, or an option is better on every point. When the item has fewer than three distinct approaches, one sentence that says why. Or "None".>
- **Wider fix:** <The letter of the option that prevents this class of issue. A structural fix, such as a helper, an abstraction, a marker, a default, or a type, ranks above a detection fix, such as a test for the class, a lint, or a guard. Or "None" and the reason, for example that the wider fix is already in force.>
- **Previous examples:** <Earlier cases of this class, with commits or files, or "None found".>
- **Related:** <Only when the item has a link to another item. Each link: the item number, the kind of link, and what it means. A link is a shared wider fix, the same cause, the same code, options that conflict, a repeat, or work that waits for the answer.>
- **Recommendation:** <Letter>. <One sentence of reasoning.> <When another option best protects the codebase, one sentence that names it.>
- **Action:** <`fix now, apply` and a letter. Or `fix after merge, apply` and a letter, with one sentence of reason. Or a split: `fix now, apply` the direct fix, `and fix after merge, apply` the wider fix, with one sentence of reason. Or `ask the user, because` and one sentence that says in plain words which condition of the decision test holds, with its evidence. Do not cite the condition by a number.>
```

In a review and in a message, a problem outside the review scope is not
an item. The `implementation-review` skill gives its one-line shape. The
final report lists it under **Open**, for a separate branch. Its
follow-up item uses this layout, as the `plans` skill says.

Keep every label, also when the user asks for more detail or for a shorter
answer. An item leaves out **Terms** and **Related** only under their
rules. For more detail, write **Background** as a list with one fact in
each item.

## Options

Give one lettered option for each real choice. Order the options from the
smallest effort to the largest, and give each its own grade. When you
explain an item again, keep the recorded letters and their order. The
wider fix of an item is one of these options.

Every writer of options follows these steps: the reviewer, the finding
check, a plan decision, and a brainstorm.

1. Write the root question in the words of the goal, not of the current
   mechanism. Ask "how does an old tab learn of a new version?", not
   "what does the detail id cover?". Put all symptoms of one problem
   under one root question. A mechanism in a brief or in the code is an
   approach, not a requirement. A requirement comes from a protocol doc,
   the choice of a user decision, or the task message.
2. Widen to at least three distinct approaches. Two approaches are
   distinct when they differ in what is built or where it lives, not
   only in a detail. When fewer than three are real, say why in one
   sentence.
3. Ask two questions. Are these the only approaches? What would you build
   if the current code did not exist? Add each approach that the
   questions give. Add "change nothing" when it meets the goal.
4. Narrow. Leave out an approach only when it fails the goal, breaks a
   requirement that stays, or another approach is better on every point.
   Give each approach that you leave out one line under **Left out**, with
   its reason, so that the user can bring it back. Each other approach is
   a lettered option.

An item from design or implementation needs one more step. Name each
assumption that all its options share. Give the source of each one: a
protocol doc, a user decision, the task message, an earlier option's
text, or the code. When an assumption is not a requirement, or its reason
is gone, add an option that drops it. A user decision covers the choice
that the user made, not each sentence of the text that describes the
chosen option. For a review item, the finding check of the
`implementation-review` skill checks these steps in a fresh context. It
also names the shared assumptions.

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

- Severity. The harm when the problem happens, not how often it happens.
  Harm to the users of the product weighs more than harm to the people
  and agents who build it. Both count. High: wrong output, lost data, a
  security problem, or blocked work. Medium: a visible defect, a spec gap
  with a workaround, or a flaky test or check in the gate. Low: wording,
  style, or a defect that costs little.
- Likelihood. How often real use meets a product bug. Give it for a
  product bug only. Common: normal use meets it, also when only now and
  then. Rare: normal use does not meet it. Only an unusual input, timing,
  platform, or setup does. A problem that an attacker can cause is a
  security problem, not a rare product bug.
- Category. Product bug, security, docs or spec, mockup, repository rule,
  test, performance, code structure, dead code, UX wording, or process.
- Effort. The grade of one option, not of the problem. It is your own
  estimate of the time that the whole job of the option takes, for the
  agent and the user together. The whole job is finding the cause, the
  change, its tests, and the review. Small: under an hour. Medium: up to
  a day. Large: longer. Use the expected change as one input: its files,
  its lines, and its kind. A new dependency, a migration, a backend and
  frontend change, a new mockup, or a new protocol section often takes
  longer. Also weigh the work that the change does not show, such as an
  unknown cause or a new test harness. No single input sets the grade. A
  typical review fix with its test is Small. The effort of an item is the
  grade of its recommended option.

## Explaining items again

Read [references/explaining-items-again.md](references/explaining-items-again.md)
before you give an earlier item again. This happens when the user asks
for an explanation, more detail, a shorter answer, or a re-print. It also
happens when a changed open item goes into a later message. The reference
says how to fill each field from the record.

## Final report

End every task with a final report. Under **Fixed**, **Deferred**, and
**Open**, keep the item order above. Use these labels:

- **Changed:** what changed, the commit, and the branch or the pull
  request.
- **Fixed:** each item that the agent fixed. Give its number, its severity,
  a plain explanation, the applied option, what changed, and the commit.
- **Deferred:** each item or wider fix with `fix after merge`. Give the
  item number, its severity, the reason, and the follow-up item. When the
  repository has a `plans/` directory, give the number of open follow-up
  items. The `plans` skill gives the script that counts them.
- **Decisions:** each item that the user answered, and its outcome. Then
  each design call that you made under the decision test, in one line:
  the call and its reason.
- **Checks:** each check and its result. Give the output of a failed
  check. Name each check that was skipped or blocked, and give the reason.
  Name each unrelated flaky test with its failure text, rerun outcome, and
  suspected source.
- **Open:** one line for each open item. The line gives the number, the
  title, the severity, the recommended option in a few words with its
  letter, and what the item blocks. Add the open plan TODOs. Add the follow-up items of the
  blocked wider fixes and of the problems outside the review scope, and
  other skipped or blocked work. A blocked wider fix is one line per class.
  The line gives the wider fix, its effort, the item numbers it covers, and
  the previous examples.

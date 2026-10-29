---
name: brainstorming
description: Use when the user asks to brainstorm, discuss, or explore an idea, asks "should we", "what do you think", or "how could we", proposes new scope or a change before a plan exists, asks for a plan whose approach is not settled, or asks for new work whose purpose, users, or measure of success is unclear.
---

# Brainstorming

A brainstorm finds the approach for an idea, a question, or a change
before a plan exists. It widens to distinct approaches, narrows them to
the real choices, and asks the user to choose. It ends with an answer, or
with the user's consent to a plan. The `plans` skill takes over from
there.

A brainstorm changes nothing in the repository. Do not edit code, docs,
or plans, and do not commit. Do not build a mockup or a spike. The
mockup milestone of the plan makes the pictures. Keep the notes, the
reports, and the user's answers under `.context/<topic>/`.

When the user's message or a recorded decision already chooses the
approach, skip the brainstorm. Go on with the request, and name the
message or the decision that chose the approach. A decision covers the
choice that the user made, not each sentence that describes it.

## 1. Read before you ask

- Read the `README.md`, the protocol docs, the architecture doc, and the
  code of the area.
- Search for earlier work on the same idea: plans, follow-up items, pull
  request descriptions, and review reports under `.context/`. In
  Conductor, also search the names of earlier workspaces, for example
  with `conductor workspace list --include-archived --name <word>`.
- An earlier proposal can hold decisions that are still open. Give them
  again with their recorded numbers and letters, as the
  `decisions-and-findings` skill says.
- Do not ask the user what the repository or the record answers.
- When the user asks for research, or an approach needs an outside
  tool, study how others solve the problem. Give each source.

## 2. Write the root question

- Write the goal as you read it: what the user wants, for whom, and why.
  Mark each guess as a guess.
- Write the root question in the words of the goal, not of the current
  mechanism. Ask "how does an old tab learn of a new version?", not
  "what does the detail id cover?".
- Put all symptoms of one problem under one root question. Do not give
  each symptom its own local options.
- A mechanism in the brief or in the code is an approach, not a
  requirement. A requirement comes from a protocol doc, the choice of a
  user decision, or the task message.

## 3. Widen

Run steps 3 and 4 as the `brainstorming` action of the `models` skill.
When your session runs the agent, the model, and the effort of that
action, do the steps yourself. Otherwise, delegate them as the `models`
skill says. Give the agent the goal, the root question, and the
requirements with their sources. Also give it the earlier work and the
paths to read. Tell it to change nothing. Do not give it your own
approaches, so that its read is not anchored on yours.

- Find at least three distinct approaches. Two approaches are distinct
  when they differ in what is built or where it lives, not only in a
  detail.
- Include the approach that you would build if the current code did not
  exist. Include "change nothing" when it meets the goal.
- Apply the options rule of the `decisions-and-findings` skill to the
  approaches. Ask its two questions. Name each condition that every
  approach keeps, with its source. Add the approach that drops a
  condition that is not a requirement.
- For each approach, give what it does, its effort grade, and its cost
  or risk.

## 4. Narrow

- Drop an approach only for one of these reasons:
  - It fails the goal.
  - It breaks a requirement that stays.
  - Another approach is better on every point.
- Give each dropped approach one line with its reason, so that the user
  can bring it back.
- Keep each approach that has a real trade-off against the others.
  Recommend one.
- Apply the decision test of the `decisions-and-findings` skill to each
  open question. A question that passes is an item. Make every other
  question a design call, and list it.

## 5. Ask the user

Check the report of a delegated step against the code before you use it.
Add the approaches that you found yourself, and narrow them in the same
way. Then write one message with every item, in the layout of the
`decisions-and-findings` skill. Use this message order:

1. One or two sentences: the recommended approach, or the root question.
2. The background, with the goal as you read it and each guess marked.
3. The shared terms.
4. The approaches, one line each. A kept approach names its option
   letter. A dropped approach gives its reason.
5. The items. The root question is one item, and its options are the
   kept approaches. Give the earlier work from step 1 under **Previous
   examples**.
6. The final report. **Changed** says that the repository did not change.
   **Decisions** lists the design calls.

Ask about the goal as an item only when a wrong guess changes the
recommended approach.

## 6. The next round

- Answers can open new questions. Ask them in the next round, all in one
  message.
- Run steps 3 and 4 again when an answer drops the recommended approach
  or adds a new one.
- Silence is not approval. An item without an answer stays open. Do not
  apply any of its options.

## 7. The end

- The brainstorm ends when the user chooses the approach or stops the
  brainstorm.
- For a question, give the answer and its reasons.
- For a change, ask for consent to write the plan, as the `plans` skill
  requires. A message that asks for the plan or the change gives that
  consent.
- The plan starts from the chosen approach. It records the other
  approaches with their reasons, each decision with its date, and each
  design call.

## Checklist

- [ ] You read the area and searched for earlier work on the same idea.
- [ ] The root question uses the words of the goal, not of the current
      mechanism.
- [ ] Steps 3 and 4 ran as the `brainstorming` action. Its brief held no
      approaches of yours.
- [ ] At least three distinct approaches. Each condition that every
      approach keeps is named with its source.
- [ ] Each dropped approach has one line with its reason.
- [ ] One message holds every item, in the `decisions-and-findings`
      layout. Every other question is a design call in the final report.
- [ ] Nothing in the repository changed.
- [ ] The plan or the change starts only after the user chose the
      approach and gave consent.

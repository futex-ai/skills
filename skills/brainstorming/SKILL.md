---
name: brainstorming
description: Use when the user asks for a feature, new scope, or a change, as in "can we", "could you", "add", or "make", and no message or recorded decision chooses how to build it, when the user asks to brainstorm, discuss, or explore an idea, asks "should we", "how could we", or "what do you think", asks for a plan whose approach is open, or asks for work with an unclear goal.
---

# Brainstorming

A brainstorm finds the approach for an idea, a question, or a change
before a plan exists. It widens to distinct approaches, narrows them,
and gives the user the options to choose from. It ends with an answer,
or with the user's choice of the approach for a change. The `plans`
skill takes over from there.

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
- Write the root question with step 1 of the options rule in the
  `decisions-and-findings` skill. Do not give each symptom its own local
  options.

## 3. Widen

Run steps 3 and 4 as the `brainstorming` action of the `models` skill.
When your session runs the agent, the model, and the effort of that
action, do the steps yourself. Otherwise, delegate them with the agent,
the model, and the effort of that action, as the `delegating` skill says.
Give the agent the goal, the root question, and the requirements with
their sources. Also give it the earlier work and the paths to read. Tell
it to change nothing. Do not give it your own approaches, so that its
read is not anchored on yours.

- Widen with steps 2 and 3 of the options rule in the
  `decisions-and-findings` skill. A brainstorm always finds at least
  three distinct approaches. The reason for fewer does not apply here.
- Name each assumption that all the approaches share, with its source,
  as the options rule says. Add the approach that drops an assumption
  that is not a requirement.
- For each approach, give what it does, its effort grade, and its cost
  or risk.

## 4. Narrow

- Narrow with step 4 of the options rule in the `decisions-and-findings`
  skill. Give each approach that you leave out one line with its reason.
- Keep each approach that has a real trade-off against the others.
  Recommend one.
- The root question is always an item for the user. Giving the user the
  options is the point of a brainstorm.
- Apply the decision test of the `decisions-and-findings` skill to each
  other open question. A question that passes is an item. Make every
  other question a design call, and list it.

## 5. Ask the user

Check the report of a delegated step against the code before you use it.
Add the approaches that you found yourself, and narrow them in the same
way. Then write one message with every item, in the layout of the
`decisions-and-findings` skill. Use this message order:

1. One or two sentences: the recommended approach, or the root question.
2. The background, with the goal as you read it and each guess marked.
3. The shared terms.
4. The approaches, one line each. An approach that is an option names
   its letter. Every other approach gives the reason that it lost.
5. The items. The root question is one item, and its options are the
   kept approaches. Give the earlier work from step 1 under
   **Previous examples**.
6. The final report. **Changed** says that the repository did not change.
   **Decisions** lists the design calls. Do not ask for consent to the
   plan or the change.

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

- The brainstorm ends when the user chooses the approach. It also ends
  when the user stops it.
- For a question, give the answer and its reasons.
- For a change, the choice gives consent to the plan, as the `plans`
  skill says. Write the plan at once. Do not ask for consent first.
- A change without code, such as a docs-only change, can go without a
  plan. Then make the change at once.
- Wait when the user says to wait. When an answer opens a question that
  can change the approach, ask it in the next round first.
- An item that stays open goes into the plan as an open decision.
- The plan starts from the chosen approach. It records the other
  approaches with their reasons, each decision with its date, and each
  design call.

## Checklist

- [ ] You read the area and searched for earlier work on the same idea.
- [ ] The root question uses the words of the goal, not of the current
      mechanism.
- [ ] Steps 3 and 4 ran as the `brainstorming` action. Its brief held no
      approaches of yours.
- [ ] At least three distinct approaches. Each assumption that all the
      approaches share is named with its source.
- [ ] Each approach that you left out has one line with its reason.
- [ ] The root question is an item for the user. One message holds every
      item, in the `decisions-and-findings` layout. Every other question
      is a design call in the final report.
- [ ] Nothing in the repository changed.
- [ ] The plan or the change started only after the user chose the
      approach. No message asked for consent to it.

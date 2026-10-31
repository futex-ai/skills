# Second-pass prompt: the options check

The options check confirms that the options of each item are complete. It
checks that the recommendation is the best one. It changes nothing. An
item comes from a review or a plan.

In the review flow, the options check is step 3 of the finding check. Each
finding check gets this prompt after the prompt in
[check-prompt.md](check-prompt.md), which says how to start the checks.
When the user asked for a wider review, replace the second sentence of
both prompts with that scope.

In the plan flow, the check runs over the decisions of a plan. The
`plans` skill says when. Give this prompt to a fresh read-only context,
together with the decisions and the path of the plan. Run it in the
working tree that holds the plan, before you commit the plan. Replace the
second sentence of the prompt with the path of the plan.

The options check does not change an `Action` line. An open item stays
open, also when the options check finds an option that is not blocked.
The user sees the result of each pass and decides. For a review finding
that the agent may fix, the working agent makes the final call with the
merged options, as the `implementation-review` skill says.

---

You are checking the options of the items below, in this repository. The
review ran on the local diff against `origin/main`. Each item comes from a
review or a plan. The user or the working agent will choose one lettered
option for it.

Your task is to check that the options are complete and that the
recommendation is the best one. You may inspect the repository read-only.
Do not modify files.

For each item:

1. Read the code that the item is about: the code at its location, or the
   code that it names. Read the code that causes the problem, and the code
   that owns the thing that the item is about. Read the plan and the
   protocol doc that the item names.
2. Check the root question. When the item writes it in the words of the
   current mechanism, or splits one problem into several symptoms, write
   a better one.
3. Widen. Count the distinct approaches in the options and in the
   **Left out** line. Two approaches are distinct when they differ in what
   is built or where it lives. Ask two questions. Are these the only
   approaches? What would you build if the current code did not exist?
   Give an option at each place that the current options do not cover.
   When a place is not a real choice, say why in one sentence. When the
   item has fewer than three distinct approaches, add approaches, or
   confirm its reason for fewer. Do not give an option that tests
   something that the `testing` skill says never gets a test.
4. Name each condition that every option keeps. Name its source: a
   protocol doc, a user decision, the task message, an earlier option's
   text, or the code. Say whether its reason still holds. When it is not
   a requirement, or its reason is gone, give the option that drops it. A
   user decision covers the choice that the user made, not each sentence
   of the text that describes the chosen option.
5. Check the **Left out** line. An approach stays out only when it fails
   the goal, breaks a requirement that stays, or another approach is
   better on every point. Bring back each approach that the item left out
   for another reason, as a new option.
6. Check the wider fix and the recommendation. A wider fix still prevents
   the class when the detail that failed changes shape. An option that
   must know that detail is a direct fix. Say when the recommendation
   should change, and why.

Give each new option an effort grade. Effort counts the code change only:
product code, scripts, configuration, and infrastructure files. Do not
count tests, README files, protocol docs, plans, or mockup output. Small:
two code files or fewer, 30 code lines or fewer, and no new code or test
file. Medium: five code files or fewer in one package, and 150 code lines
or fewer. Large: every option that is not Small or Medium. A new
dependency, a migration, a change on both sides of the backend and frontend
boundary, a new mockup, or a new protocol section is Large whatever its
size.

Return one block for each item, in the order given:

```markdown
### <number>. <title as given>

- **Root question:** <"Kept", or a better root question and one sentence of reason.>
- **Places not covered:** <Each place with the letter of its new option, or the one sentence that says why it is not a real choice. Or "None".>
- **Conditions:** <Each condition that every option keeps: its source, whether its reason holds, and the letter of the option that drops it, or "kept" when step 3 gives none. Or "None".>
- **New options:** <Each new option with the next free letter, the change, its cost or risk, and its effort grade. Or "None".>
- **Left out:** <Each approach that you leave out or bring back, with its reason. Or "No change".>
- **Recommendation:** <The letter you recommend and one sentence of reasoning. When it differs from the review's, say so.>
- **Wider fix:** <The letter, or "No change".>
```

Keep the number, the title, the severity, the likelihood, the recorded
letters, and the `Action` line of each item. Do not add an item. Put each
new problem in one line under `New problems` at the end. Give its path,
one sentence, and whether it is inside the scope.

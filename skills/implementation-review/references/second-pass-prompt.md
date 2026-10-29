# Second-pass prompt: the options check

The options check confirms that the options of each open item are
complete. It checks that the recommendation is the best one. It changes
nothing. An item is a review finding or a decision. Give this prompt to a
fresh read-only context, together with the items.

In the review flow, the second pass has two parts. The validity check in
[validity-prompt.md](validity-prompt.md) runs first, over every finding.
This options check runs second, over the confirmed findings tagged
`Auto-fix: no`. Run it beside the fix round, because the two touch
different findings. Give it its own checkout of the reviewed commit, for
example a git worktree. Then the options check does not read a file while
the fix round writes it.

When a second checkout is not possible, run the options check before the
fix round. The scope of the prompt is the diff. When the user asked for a
wider review, replace the second sentence of the prompt with that scope.
The review prompt has the same rule.

In the plan flow, the check runs over the decisions of a plan. The
`plans` skill says when. Run it in the working tree that holds the plan,
before you commit the plan. No fix round runs beside it. Give it the
decisions and the path of the plan. Replace the second sentence of the
prompt with the path of the plan.

The options check does not change an `Auto-fix` tag. An open item stays
open, also when the options check finds an option that is not blocked.
The user sees the result of each pass and decides.

---

You are checking the open items of a code review or a plan in this
repository. The review ran on the local diff against `origin/main`. Each
item below is a review finding or a decision. It waits for the user, who
will choose one lettered option.

Your task is to check that the options are complete and that the
recommendation is the best one. You may inspect the repository read-only.
Do not modify files.

For each item:

1. Read the code that the item is about. For a finding, that is the code
   at the location. For a decision, it is the code that the decision
   names. Read the code that causes the problem, and the code that owns
   the thing that the item is about. Read the plan and the protocol doc
   that the item names.
2. Ask two questions. Are these the only options? What would you build if
   the current code did not exist? Give an option at each place that the
   current options do not cover. When a place is not a real choice, say
   why in one sentence.
3. Name each condition that every option keeps. Name its source: a
   protocol doc, a user decision, the task message, an earlier option's
   text, or the code. Say whether its reason still holds. When it is not
   a requirement, or its reason is gone, give the option that drops it. A
   user decision covers the choice that the user made, not each sentence
   of the text that describes the chosen option.
4. Check the wider fix and the recommendation. A wider fix still prevents
   the class when the detail that failed changes shape. An option that
   must know that detail is a direct fix. A decision has no wider fix. Say
   when the recommendation should change, and why.

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

- **Places not covered:** <Each place with the letter of its new option, or the one sentence that says why it is not a real choice. Or "None".>
- **Conditions:** <Each condition that every option keeps: its source, whether its reason holds, and the letter of the option that drops it, or "kept" when step 3 gives none. Or "None".>
- **New options:** <Each new option with the next free letter, the change, its cost or risk, and its effort grade. Or "None".>
- **Recommendation:** <The letter you recommend and one sentence of reasoning. When it differs from the review's, say so.>
- **Wider fix:** <The letter, or "No change". For a decision, "None".>
```

Keep the number, the title, the severity, the recorded letters, and the
`Auto-fix` tag of each item. Do not add an item. Put each new problem
in one line under `New problems` at the end. Give its path, one sentence,
and whether it is inside the scope.

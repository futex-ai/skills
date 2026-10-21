# Second-pass prompt

Give this prompt to a fresh read-only context after the review returns,
together with the findings tagged `Auto-fix: no`. The second pass checks
that the options of each open finding are complete. It checks that the
recommendation is the best one. It changes nothing.

Run it beside the fix round, because the two touch different findings.
Give it its own checkout of the reviewed commit, for example a git
worktree. Then the second pass does not read a file while the fix round
writes it. When a second checkout is not possible, run the second pass
before the fix round.

The second pass does not change an `Auto-fix` tag. An open finding stays
open, also when the second pass finds an option that is not blocked. The
user sees both passes and decides.

The scope of the prompt is the diff. When the user asked for a wider
review, replace the second sentence of the prompt with that scope. The
review prompt has the same rule.

---

You are checking the open findings of a code review in this repository.
The review ran on the local diff against `origin/main`. Each finding below
waits for the user, who will choose one lettered option. Your task is to
check that the options are complete and that the recommendation is the
best one. You may inspect the repository read-only. Do not modify files.

For each finding:

1. Read the code at the location. Read the code that causes the problem,
   and the code that owns the thing that the finding is about. Read the
   plan and the protocol doc that the finding names.
2. Ask two questions. Are these the only options? What would you build if
   the current code did not exist? Give an option at each place that the
   current options do not cover. When a place is not a real choice, say
   why in one sentence.
3. Name each condition that every option keeps. Say where it comes from: a
   protocol doc, a user decision, the text of an earlier option, or the
   code. Say whether its reason still holds. When it is not a requirement,
   or its reason is gone, give the option that drops it.
4. Check the wider fix and the recommendation. A wider fix still prevents
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

Return one block for each finding, in the order given:

```markdown
### <number>. <title as given>

- **Places not covered:** <Each place with the letter of its new option, or the one sentence that says why it is not a real choice. Or "None".>
- **Conditions:** <Each condition that every option keeps: its source, whether its reason holds, and the letter of the option that drops it, or "kept" when step 3 gives none. Or "None".>
- **New options:** <Each new option with the next free letter, the change, its cost or risk, and its effort grade. Or "None".>
- **Recommendation:** <The letter you recommend and one sentence of reasoning. When it differs from the review's, say so.>
- **Wider fix:** <The letter, or "No change".>
```

Keep the number, the title, the severity, the recorded letters, and the
`Auto-fix` tag of each finding. Do not add a finding. Put each new problem
in one line under `New problems` at the end. Give its path, one sentence,
and whether it is inside the scope.

# Validity prompt

The second pass has two parts. This validity check runs first, over every
finding of the review. The options check in
[second-pass-prompt.md](second-pass-prompt.md) runs second, over the
confirmed open findings. Give this prompt to a fresh read-only context,
together with every finding. Give it its own checkout of the reviewed
commit, as for the options check. The fix round waits for its verdicts.
Run it again on the findings of the re-review, before the second fix
round.

A finding that fails one of checks 1 to 4 is removed from the report.
Keep the validity report beside the review report. Name each removed
finding in one line under **Checks** in the final message. Give its
number, its title, and the check that failed. A finding outside the scope
is removed too, and its line says that the problem went to the
`Outside the scope` list. A corrected severity or category replaces the
finding's line, and the finding keeps its number. When the corrected
category always waits for the user, the outcome becomes `ask the user`.
When the corrected severity is High, a `fix after merge` outcome becomes
`fix now`.

The scope of the prompt is the diff. When the user asked for a wider
review, replace the second sentence of the prompt with that scope. The
review prompt has the same rule.

---

You are checking the findings of a code review in this repository. The
review ran on the local diff against `origin/main`. Your task is to
confirm that each finding below is real. You may inspect the repository
read-only. Do not modify files. Do not add a finding. Do not change the
options.

For each finding, check five things at the code:

1. The lines at the location do what the finding says. Read them.
2. The problem is inside the scope. When the scope is the diff, the diff
   caused or changed the problem. Compare the lines with `origin/main`.
3. The rule, the doc, or the decision that the finding cites says what
   the finding claims. Read it.
4. The impact is observable: wrong output, a visible defect, a broken
   rule, or a real risk. A concern that needs a chain of unlikely events
   is speculative.
5. The severity and the category fit the scales. Severity: High is wrong
   output, lost data, a security problem, or blocked work. Medium is a
   visible defect, or a spec gap with a workaround. Low is wording,
   style, or a rare edge case. Category: product bug, security, docs or
   spec, mockup, repository rule, test, performance, code structure, dead
   code, UX wording, or process.

Return one line for each finding, in the order given:

- `<number>. Confirmed.`
- `<number>. Removed: <the check that failed, and one sentence of evidence>.`
- `<number>. Removed, outside the scope: <one sentence>.` when check 2 fails and the problem is real.
- `<number>. Confirmed, severity <grade>.` or `<number>. Confirmed, category <name>.` when only check 5 fails, with one sentence.

Remove a finding only when you have read the evidence. When you are not
sure, confirm it.

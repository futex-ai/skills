# Check prompt: one finding

The finding check is the second pass of the review. One check runs for
each new finding, before the fix round. The check confirms that its
finding is real, finds the links to the other findings, and checks the
options of its finding. It changes nothing.

## Starting the checks

- Start one check for each new finding of the round, side by side. Each
  check is a fresh read-only `second-pass review agent` of the `models`
  skill.
- Run each check as an in-session subagent when the `delegating` skill
  allows one for your agent. Its report then comes straight back to you.
- When the tool refuses a check because too many checks run at once,
  start that check when an earlier check ends.
- Start the checks before you edit any file, so that every check reads the
  code that the review read. A check needs no second checkout.
- Give each check the prompt below, followed by the prompt in
  [second-pass-prompt.md](second-pass-prompt.md). Replace `<number>` with
  the number of its finding. Replace `<findings file>` with the path of
  the findings file, relative to the repository root.
- When a check runs outside this checkout, paste the findings file into
  its prompt in place of the path.
- The scope of the prompt is the diff. When the user asked for a wider
  review, replace the second sentence of the prompt with that scope. The
  review prompt has the same rule.

The `implementation-review` skill says how to merge each report into the
findings file.

---

You are checking one finding of a code review in this repository. The
review ran on the local diff against `origin/main`. Your finding is
number <number> in `<findings file>`. That file holds every finding of the
review. You may inspect the repository read-only. Do not modify files. Do
not add a finding.

Work in three steps, in this order.

## Step 1: confirm the finding

Check five things at the code, and a sixth for a missing test:

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
6. A finding about a missing test names the requirement or the defect that
   no test covers. It also names a code change that no existing test
   catches. Read the tests to confirm that none catches it. Remove the
   finding when it names no requirement and no defect, or no such change.

Write one verdict line:

- `<number>. Confirmed.`
- `<number>. Removed: <the check that failed, and one sentence of evidence>.`
- `<number>. Removed, outside the scope: <one sentence>.` when check 2 fails and the problem is real.
- `<number>. Confirmed, severity <grade>.` or `<number>. Confirmed, category <name>.` when only check 5 fails, with one sentence.

Remove the finding only when you have read the evidence. When you are not
sure, confirm it. When you remove the finding, return the verdict line and
stop.

The file can also hold the findings of earlier rounds, each with a status.
An earlier status is not evidence. Judge your finding at the code.

## Step 2: find the links

Read the other findings in the file. A link is one of these:

- a shared wider fix
- the same cause
- the same code
- options that conflict
- a repeat: the same problem at the same place

For each link, give the number of the other finding, the kind of link,
and what the link means for the options of your finding. A shared cause
can give one fix for both findings.

## Step 3: check the options

The options check follows this prompt, after the `---` line. It is
written for a list of items. Use it for your finding only. Where it says
"the items below", it means your finding in the findings file.

Keep the links of step 2 in mind while you look for options. For example,
a shared cause can give one fix for both findings. A conflict can need an
option that works with the options of the other finding.

## Return

1. The verdict line.
2. The block of the options check. Put this line first in the block:
   `- **Related:** <Each link: the number, the kind of link, and what it means. Or "None".>`
3. The `New problems` list of the options check.

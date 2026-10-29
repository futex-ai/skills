# Findings file

The findings file records every review finding of one branch, from the
first review to the merge. A new session, or a session after a context
summary, reads it to continue the review work.
[../templates/findings.md](../templates/findings.md) is the layout.

Git ignores the file, so it stays in the workspace. Findings leave the
branch only as text: a follow-up item, the pull request description, or a
message to another agent.

## Where it lives

- The file is `.context/reviews/<branch>/findings.md`. Replace each `/` in
  the branch name with `-`. Its folder is the review folder of the branch.
- Save the full report of each pass in the review folder:
  `round-<number>-review.md` for the review, and
  `round-<number>-checks.md` for the finding checks of that round.
- Each branch has its own file. Do not edit the file of another branch.
  To pass a finding to another agent, give it the text of the entry.

## Who edits it

- Only the working agent of the branch edits the file. The working agent
  is the session that runs the review and the fixes.
- The finding checks read the file. They do not edit it.
- Write each new finding before the checks start. Merge the check reports
  after every check ends. So no agent reads the file while another agent
  edits it.
- The reviewer does not read the review folder, so that each review stays
  independent of the earlier rounds.

## Numbers

- Each finding number is used only once in the branch.
- Give each reviewer the first free number: one more than the highest
  number in the file, or 1 for the first round. The reviewer numbers its
  findings from there.
- A finding keeps its number for the life of the branch, also when it is
  removed or repeats another finding.

## Status

Each entry has one status:

- **New:** the review gave the finding, and its check has not reported.
- **Removed:** its check removed it. The history gives the check that
  failed.
- **Fix now:** the finding is confirmed, and its fix is not committed yet.
- **Fixed:** the fix is committed. Give the commit.
- **Deferred:** the outcome is `fix after merge`. Give the follow-up item.
- **Open:** the finding waits for the user. Give the follow-up item.
- **Repeat:** the finding repeats an earlier finding. Give its number.
- **Dropped:** the user dropped the finding.

A split finding is Fixed. Its status also gives the follow-up item of the
wider fix.

## When to update it

Update the file at each of these points, before you continue:

- A review reports. Record the round. Write each new finding as the review
  gave it, with the status New.
- The checks report. Merge each check into its entry, as the
  `implementation-review` skill says.
- You make the final call on an outcome.
- You commit a fix, or you record a follow-up item.
- The user answers a finding. Record the answer and its date. Then give
  the finding the status Fix now, Deferred, or Dropped.

Give each event one dated line under **History**. Do not change an
earlier line.

## Merging a check report

Each finding check returns a verdict line, a block of links and options,
and a list of new problems. Merge them into the entry of the finding:

- A Removed verdict gives the status Removed. The history gives the check
  that failed. A finding outside the scope goes to the
  `Outside the scope` list.
- A corrected severity or category replaces the finding's line. When the
  corrected category always waits for the user, the outcome becomes
  `ask the user`. When the corrected severity is High, a
  `fix after merge` outcome becomes `fix now`.
- Each link goes into the **Related** line of both findings. Drop a link
  to a removed finding.
- A new option keeps the letter that the check gave it. The source of a
  dropped condition goes into the text of the option that drops it.
- When the recommendation changed, the **Recommendation** line gives the
  new letter and its reason. It then names the letter that the first pass
  recommended. The **Wider fix** line takes the new letter in the same
  way.
- A new problem inside the scope goes into the review focus of the
  re-review. When no re-review runs, it goes under **Open**. A new problem
  outside the scope joins the `Outside the scope` list.
- A kept condition and a place that is not a real choice stay in the
  saved check report, `round-<number>-checks.md`.

## Repeats

The re-review does not see the earlier rounds, so it can raise a finding
again. The check of the new finding then reports the repeat as a link.

- A repeat of a Fixed or Removed finding stays a finding. A second
  independent reviewer found it, so the fix or the removal can be wrong.
  Its check confirms it or removes it.
- Any other repeat gets the status Repeat and no fix of its own. The
  earlier entry gets a history line that names the repeat.

## The final report

Build the **Fixed**, **Deferred**, and **Open** lists of the final report
from the file. Name each removed finding under **Checks**. The
`decisions-and-findings` skill gives the layout.

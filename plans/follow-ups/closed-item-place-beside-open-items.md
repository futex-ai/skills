# Closed item has no place beside open items

- **Severity:** Low. **Effort:** Small. **Confidence:** High. **Harder later:** No.
- **Kind:** Outside the scope.
- **Added:** 2026-11-01, from the branch `calummoore/findings-reprint-skill`, review round 2, finding 5.
- **Location:** `skills/decisions-and-findings/SKILL.md`, the sections "Open items" and "Item order". `skills/decisions-and-findings/references/explaining-items-again.md`. `skills/findings/SKILL.md`, the section "What to print".
- **Reason:** The fix adds a layout rule for what the user sees, and the user reviews each new rule of that kind.

- **Terms:**
  - **Open item:** an item of the conversation that waits for the user's answer.
  - **Closed item:** an item that does not wait for the user. The user answered it, an agent fixed it, it was deferred, or the user dropped it.
- **Background:**
  - The `decisions-and-findings` skill puts all the items of a message in one list, ordered by severity. The user chose one list on 2026-10-29.
  - Its "Open items" section gives each new, changed, or asked-for open item in full under the heading `## Needs your answer`, before the final report.
  - A closed item can also come in full. The user can ask to explain it, under "Explaining items again". The user can also name it in a call of the `findings` skill.
- **Problem:** No rule says where a closed item in full goes when the same message also gives open items in full. In the one list, the closed item sits under `## Needs your answer`, although it needs no answer.
- **Impact if no action:** A message can show an answered or fixed item under the heading that asks for an answer. Only the outcome sentence under its title says that it is closed.
- **Root question:** Where does a message put a closed item that it gives in full, beside open items that it gives in full?
- **Options:**
  - **A.** Keep one list under `## Needs your answer`. The outcome sentence under the title of each closed item marks it. Nothing changes in the text. Effort: Small.
  - **B.** Keep the open items under `## Needs your answer`. Give the closed items in full after them, under their own heading, such as `## Other items`. Each group keeps the severity order. Write the rule once in `decisions-and-findings`. "Explaining items again" and the `findings` skill point to it. Effort: Small.
  - **C.** Give each closed item in full inside the final report, under the label of its outcome. The final report then gets long. Effort: Small.
- **Left out:** One list with a mark on each open item breaks the rule that open items stand under `## Needs your answer`. A test of the skill text is left out, because skills get no tests.
- **Wider fix:** B. One shared rule covers every message that gives a closed item in full.
- **Previous examples:** Commit `7fc0faf` merged two item lists into one list, ordered by severity.
- **Recommendation:** B. It keeps the open items at the top, and it says plainly which items need no answer.
- **Action:** ask the user, because B adds a layout rule for what the user sees, and it splits the one list that the user chose on 2026-10-29.

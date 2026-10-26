# Sentence-length warning in the skill check

Status: Active. [PR #26](https://github.com/futex-ai/skills/pull/26) is
open. The plan closes when its PR merges.

The always-on rules ask for Simplified Technical English (STE) in every
skill. STE gives an instruction 20 words or fewer. The skill check is
`scripts/check.sh`. It validates the frontmatter, the name, the description
length, and the file length of every skill. It also validates the file
references and the scripts. CI runs it as its own step before
`tests/run.sh`. It has no sentence rule, so only a review catches a long
sentence. The Terms slot change is
[PR #22](https://github.com/futex-ai/skills/pull/22). Both of its review
rounds found STE slips. They found six long sentences, two passive
sentences, and one term used for two things. Its fix commit `f3b85c5`
records finding 2. The commit says: "the two new rule sentences are split
so that each holds one instruction of 20 words or fewer".

The change adds a warning to the skill check. The check lists each sentence
of more than 20 words in the prose of a `SKILL.md` file. It skips the
frontmatter, the headings, the table rows, and the fenced code. A warning
does not fail the run. The change also splits each such sentence in the 16
`SKILL.md` files, so that the check prints no sentence warning. The change
does not cover `references/`, `templates/`, `global/AGENTS.md`, or
`README.md`.

Decision of 2026-10-20: the user chose option B, a warning. Option A was no
check, with the `writing-skills` checklist and the review as the only
control. Option C was an error. It would block every quoted excuse and
every long lead-in, so it needed an exception list. Reason: a warning gives
the signal at check time and blocks nothing.

[PR #23](https://github.com/futex-ai/skills/pull/23) recorded "No check for
the STE limits in skill prose" for a finding of its own review. That
decision came at 10:47 UTC on 2026-10-20. The user asked for this plan at
11:22 UTC and for its implementation at 11:46 UTC. So option B stands here.

Decision of 2026-10-21, review finding 1: a `.`, `!`, or `?` inside a code
span ends the sentence. The user chose option A: keep the rule, and state
the limit in the code comment and in this plan. Option B ended no sentence
inside a code span. Option C counted each code span as one word. The user
gave no reason. Option A keeps the word rule and every current warning.

Decisions of 2026-10-26. On 2026-10-20 decisions 1 and 2 had no answer.
Their recommended options applied as defaults.
[PR #27](https://github.com/futex-ai/skills/pull/27) reopened them on
2026-10-21: silence is not approval. The user then answered them:

- Decision 1, the existing long sentences: option B, split them in this
  change. Option A left them. Option C, the recommendation, split them on
  a separate branch after the merge. The user gave no reason. The merge
  now waits for the split.
- Decision 2, the scope of the scan: option A, `SKILL.md` only. Option B
  also scanned `references/` and `templates/`. The user gave no reason.
- Review round 3, finding 2: option A. The plan states what decision 1
  blocks. With decision 1 answered, the split is part of this change. So
  the merge waits for it.

The scan measured `main` at `69c40ed` on 2026-10-20. The 16 `SKILL.md`
files hold 112 sentences of more than 20 words, from 1 to 19 per skill.
They hold 37 sentences of more than 25 words. The `references/` files hold
76 more, the `templates/` files 6, `global/AGENTS.md` 7, and `README.md`
14. The first prototype counted 113 on `fbd6783`. It lost the last
paragraph of a file when it read more than one file. Evidence:
`.context/skill-check-sentence-warning/`, files `check-output.txt` and
`prototype-per-file-69c40ed.txt`.

Contract owners:

- The [README](../README.md), sections "Layout" and "Writing a skill".
- The [`writing-skills` skill](../skills/writing-skills/SKILL.md), section
  "The SKILL.md file".

## Design

- A new file, `scripts/lib/check-sentences.sh`, holds one function,
  `long_sentences <file> <max>`. `check.sh` sources it, as `update.sh`
  sources its `lib/` files. The function runs a POSIX awk program. It
  prints one line per sentence of more than `<max>` words. The line gives
  the line where the sentence starts, the word count, and the first eight
  words. Tabs separate the fields.
- The program skips the frontmatter, the fenced code blocks, and every
  line that starts with `#` or `|`. A run of three or more backticks or
  tildes opens a fenced block. A run of the same character that is at
  least as long closes it. A blank line, a heading, a table row, a fence,
  or a list marker ends a paragraph. The program strips the list marker
  and a `[ ]` checkbox.
- A sentence continues on the next line of its paragraph. It ends at `.`,
  `!`, or `?` followed by a space or the end of the line. Closing quotes,
  brackets, or backticks may stand between the punctuation and the space.
  A lead-in that ends with a colon counts as one sentence. A word is a
  whitespace-separated token, so a code span or a link counts as one word
  per token.
- The scan does not parse code spans. A `.`, `!`, or `?` inside a code span
  also ends the sentence. A long sentence with such a code span can then
  give no warning. Example: on `69c40ed`, the `plans` skill holds a 30-word
  sentence of this kind at line 101. The decision of 2026-10-21 keeps this
  limit.
- `check.sh` keeps `max_words=20`. It prints one warning for each listed
  sentence, in this shape:

  ```text
  warning: <name>: SKILL.md:<line>: sentence has <n> words (max 20): <first eight words> ...
  ```

  When the awk program fails, `check.sh` warns that the sentence scan
  failed for that skill and continues. The run still ends with
  `all skills valid` and exit 0 when it has no error.
- Portability: POSIX awk only, so no gawk functions, no interval
  expressions. The check also runs on macOS with BSD awk and bash 3.2.
- Effort under the review scale: Medium. The awk program passes 30 lines
  and lives in a new helper file.

## Milestone 1: Documentation

The README and the `writing-skills` skill state the new rule and name the
new `plans/` directory.

- [x] Read the `documentation` skill. Add `plans/` to the README "Layout"
      section with a link to the directory.
- [x] In the README "Writing a skill" section, add one bullet. It says that
      the check warns about a `SKILL.md` sentence of more than 20 words. It
      says that the check skips frontmatter, headings, tables, and code.
- [x] In `skills/writing-skills/SKILL.md`, extend the STE bullet of "The
      SKILL.md file". Add that the repository check warns about a sentence
      of more than 20 words. Keep the file near 150 lines.
- [x] Record the outcome of decisions 1 and 2 above with the date.

## Milestone 2: The sentence scan and its tests

`check.sh` lists the long sentences of every skill. A new shell test covers
the scan and the exit status of the check.

- [x] Add `scripts/lib/check-sentences.sh` with `long_sentences`, a header
      comment in the style of the other `lib/` files, and the
      `shellcheck shell=bash` directive. Start from the prototype under
      `.context/skill-check-sentence-warning/sentences.awk`.
- [x] Source the file in `check.sh`. Call `long_sentences "$file" 20` in
      the skill loop and print one warning per line. Update the header
      comment of `check.sh`.
- [x] When the awk program fails, warn and continue, so that the check
      does not stop for a warning.
- [x] Add `tests/check_test.sh`. Its fixture copies `scripts/` into a temp
      directory and writes `skills/<name>/SKILL.md` files. `tests/run.sh`
      picks the file up by its name.
  - [x] A 21-word sentence gives one warning with the skill name, the line,
        and the count. A 20-word sentence gives none. The run exits 0 and
        prints `all skills valid`.
  - [x] A long sentence wrapped over two lines gives one warning with the
        first line's number. Two short sentences on one line give none.
  - [x] A long sentence in a checkbox list item gives a warning. Two
        short list items are not joined.
  - [x] A long description in the frontmatter gives no warning. A long
        table row, a long heading, and a long sentence in a fenced block
        give no warning.
  - [x] A sentence that ends with `.)`, or with a code span before the
        period, splits where it should.
  - [x] A missing `SKILL.md` still exits 1, with or without warnings.
  - [x] A sentence that starts in the middle of a paragraph gives its own
        line. A fence of four backticks holds a fence of three.
  - [x] A failed scan gives the scan warning, and the run exits 0.
  - [x] Each test fails when the scan rule that it covers is broken.
        Evidence: `.context/skill-check-sentence-warning/mutations.txt`.
- [x] Run `scripts/check.sh` on the repository. Save the output under
      `.context/skill-check-sentence-warning/check-output.txt` and confirm
      that the count matches the baseline for decision 1. It gives the same
      112 sentences as the prototype, run one file at a time.
- [x] Apply the outcome of decision 2 to the file glob when the user chose
      option B. Decision 2 kept option A, so the scan reads `SKILL.md` only.

## Milestone 3: Verification, commit, and review

- [x] Run `scripts/check.sh`, `shellcheck -x` on `scripts/*.sh`,
      `scripts/lib/*.sh`, and `tests/*.sh`, `tests/run.sh`, and the
      trailing-whitespace grep from `.github/workflows/check.yml`.
  - [x] Run the scan with gawk, `gawk --posix`, mawk, and busybox awk.
        Also run it with Apple's awk 20200816, built from its source. Use
        bash 5.2 and bash 3.2.57. Evidence:
        `.context/skill-check-sentence-warning/portability/`.
- [x] Run `scripts/check.sh` on macOS with BSD awk, through the user's Mac,
      and compare the warning lines with the Linux run. Save the diff under
      `.context/skill-check-sentence-warning/`.
  - Blocked on 2026-10-20 and 2026-10-21: the Mac did not answer two
    requests on each day. Apple's libc source shows that its C locale
    accepts every byte, so Apple awk reads non-ASCII text there. Evidence:
    `portability/notes.md` under `.context/skill-check-sentence-warning/`.
  - Done on 2026-10-26 with macOS 15.7.3, BSD awk 20200816, and bash
    3.2.57. The output matches Linux byte for byte at `79352941` and at
    `ce4cf6c`, in three locales. The tests pass 7 of 7. Evidence: the same
    `portability/notes.md`.
- [x] Commit with Conventional Commits, for example
      `feat(check): warn about sentences over 20 words`, and push the
      branch. Say in the PR description that an installed clone gets the
      new check when `scripts/update.sh` runs there.
- [x] Review the complete local diff against `origin/main` with the
      `implementation-review` skill after the push. Report the findings,
      then apply the review-fix rule: fix the `Auto-fix: yes` findings,
      re-review once, and report the rest.
  - Round 1 fixed finding 3: the `tests/lib.sh` header. Round 2 found no
    findings. Reports: `round-1.md` and `round-2.md` under
    `.context/skill-check-sentence-warning/review/`.
  - Finding 1 is closed. On 2026-10-21 the user chose A: keep the rule and
    state its limit.
  - 2. Four stated scan rules have no test. Severity Low, effort Small.
    Recommended: A, add cases to the two existing tests.
  - `skills/decisions-and-findings/SKILL.md`: 206 lines, so the check
    warns above 200. Separate branch.
- [x] Apply the user's decision of 2026-10-21 on finding 1, option A. State
      the code-span limit in the header comment of
      `scripts/lib/check-sentences.sh` and in the design above.
- [x] Commit and push the decision change.
- [x] Review the decision commit with the `implementation-review` skill.
      Fix its `Auto-fix: yes` findings once, then report the rest.
  - Round 3 found four Low findings. The fix round fixed findings 3 and 4.
    The docs now say "fenced code blocks". Each open decision is now a list
    with a reason. Report: `round-3.md` under
    `.context/skill-check-sentence-warning/review/`.
  - Round 3, finding 1. No test pins the kept code-span rule. Severity Low,
    effort Small. Recommended: A, add one line to the closing-marks test.
  - Round 3, finding 2 is closed. On 2026-10-26 the user chose A, and
    decision 1 has an answer.
  - `README.md` and the `writing-skills` skill promise a warning for each
    sentence over 20 words. The code-span limit hides some. Separate
    branch.

## Milestone 4: Split the long sentences

Decision 1 of 2026-10-26 moves the split into this change. After the merge
of `main` at `ae1a2c2`, the 16 `SKILL.md` files hold 110 sentences of more
than 20 words. The code-span limit hides one more, at line 101 of the
`plans` skill. Each one becomes shorter sentences of 20 words or fewer,
with the same meaning.

- [x] Merge `origin/main` into the branch, because PR #27 changed two of
      the skills. Run the merge audit.
- [x] Merge `origin/main` again at `414ddd5`, because PR #28 conflicted
      with the split in three skills. Keep every line of PR #28. The check
      still prints no sentence warning.
- [x] Split the long sentences of each skill in its own commit, with the
      type `style`. Keep the meaning, the terms, and the line width of the
      file. Do not change a paragraph that has no long sentence.
  - Two sibling list items changed too, so that their lists stay alike.
    They are the deletion options in `agents-md` and the reference kind in
    `writing-skills`. Each edited paragraph also lost its semicolons and
    its clauses in parentheses.
  - The example description in `writing-skills` is a fenced YAML line, not
    a split quote. A description is one sentence.
  - [x] Compare the content words of each file before and after the split.
        Only inflections and joining words changed. Evidence:
        `.context/skill-check-sentence-warning/split/`.
  - [x] Keep each paragraph at six sentences or fewer. Two paragraphs
        already hold ten. Split them at a natural break. Both are nested
        lists now.
  - [x] Keep the line count of each `SKILL.md` close to its current count.
        No skill crosses 200 lines because of the split. The
        `decisions-and-findings` skill grows from 206 to 209 lines, and
        `implementation-review` from 164 to 175.
- [x] Run `scripts/check.sh`: it prints no sentence warning. Run the
      complete gate.
- [x] Commit and push. Update the PR description.
- [x] Review the split with the `implementation-review` skill after the
      push. Report the findings, then apply the review-fix rule: fix the
      `Auto-fix: yes` findings, re-review once, and report the rest.
  - Round 4 found three Low findings. The fix round fixed findings 1 and
    2: two splits had weakened an "only" condition. It also fixed one more
    case of that class in the `plans` skill. Report: `round-4.md` under
    `.context/skill-check-sentence-warning/review/`.
  - Round 4, finding 3. Four commit titles have 51 or 52 characters, and
    two merge titles have 66. Severity Low, effort Small. Recommended: A,
    keep them and keep later titles within 50.
  - Open decision: a split rule in the `writing-skills` skill. Effort
    Small. It is the wider fix of round-4 findings 1 and 2. Round 5 found
    three more splits of that shape, in `implementation-review` and
    `deterministic-tests`. It blocks the merge, because one option rewords
    those splits in this change.
  - Round 5 reviewed the fix commit and found two Low findings. The fix
    round fixed both. The PR description now lists round 4 and its open
    items, and this line records round 5. Report: `round-5.md` under
    `.context/skill-check-sentence-warning/review/`.
  - `scripts/check.sh`: on macOS, `wc -l` pads the count in the 200-line
    warning with spaces. Separate branch.
  - `plans/skill-check-sentence-warning.md`: the opening paragraph holds
    12 sentences. Separate branch.
  - `skills/*/SKILL.md`: 18 semicolons stay in paragraphs that the split
    did not edit. Separate branch.

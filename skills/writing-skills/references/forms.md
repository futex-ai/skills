# Forms that fix a failure

Each section shows one form from the table in `SKILL.md`. The examples
use the layout of the shared skills. Replace the content with your own.

## A prohibition with an excuse table and red flags

For a rule that the agent knows and skips under pressure. State the rule
as a prohibition. Then answer each recorded excuse. Then list the words
that show the agent is about to skip the rule.

```markdown
Run the complete gate once before you say work is complete. A filtered
run is partial verification. It does not replace the gate.

| The excuse | The answer |
| --- | --- |
| "The targeted tests pass. That is enough." | They cover the change. The gate covers what the change broke elsewhere. |
| "The gate takes 20 minutes and the user is waiting." | Say that the gate runs and how long it takes. The user can skip it. You cannot. |

Red flags: you wrote "should be fine", you plan to run the gate after
the push, or you call a partial run "the tests".
```

The rows above show the layout only. Build real rows from excuses that a
baseline or a pressure test recorded verbatim. Add one sentence to the
skill: a workaround that keeps the words of the rule and loses its
purpose breaks the rule.

## A recipe with a template

For an output that has the wrong shape. Give the steps in order. Then
give a template with every label, and one sentence for what each field
holds. The `decisions-and-findings` skill does this for a decision:

```markdown
### 1. <The problem, in eight words or fewer>

- **Severity:** <High, Medium, or Low>. **Effort:** <Small, Medium, or Large>.
- **Problem:** <One to three sentences that say what is wrong.>
- **Options:**
  - **A.** <The change.> <Its cost or risk.>
- **Recommendation:** <Letter>. <One sentence of reasoning.>
```

## A required slot

For an element that the agent leaves out. Give the element a label in the
template, and add a sentence that says it is always present.

```markdown
- **Auto-fix:** `yes`, or `no, because` and the condition that stops the fix.

Always write **Background**, **Problem**, **Impact if no action**, and
**Options**. Keep every label, also when the user asks for a shorter
answer.
```

## A condition with a plain predicate

For a rule that the agent applies in the wrong case. Say when the rule
applies and what to do in each case. Do not write an exception clause.

Weak: "Fix a flaky test yourself unless the fix is risky."

Strong, from the `deterministic-tests` skill:

```markdown
A flaky test that the diff adds or changes may be fixed without asking
only when all of these hold:

1. Reproduce the flake by repeating the test.
2. Name the nondeterminism source.
3. Make the test deterministic with the methods above.
4. Keep every existing assertion.
5. Add no retry, sleep, repeat, skip, quarantine, or longer time limit.

An unreproducible failure, an unknown source, or a proposed removal stays
`Auto-fix: no`.
```

## Symptom keywords in the description

For a skill that the agent does not load. Name what the agent sees at the
moment, not the topic alone.

Before: "Rules for tests that must not depend on machine speed."

After: "Use when a test fails and then passes on a rerun, when a test
would assert elapsed time, timeouts, or performance, or when you choose
between a real and a fake clock. Covers operation counts, captured inputs,
event order, fake clocks, and the flaky-test procedure."

The second text names the rerun that passes and the assertion on elapsed
time. Those are the words in the agent's context at the moment.

# Removing a test

A test that protects nothing that another test protects still costs run
time on every gate. It also needs an edit when the code that it reads
changes. The `testing` skill says when you remove such a test without
asking the user. This file gives the steps.

## Steps

1. Name the reason: a duplicate, removed behaviour, or the list under
   "What never gets a test" in the `testing` skill.
2. For a duplicate, name the test that covers the same requirement at the
   same level or lower.
3. For a duplicate, prove the cover. Break the product code once, in the
   way that the removed test catches. Run the covering test and see it
   fail on an assertion. Restore the code. Save the command and its output
   under `.context/`.
4. For removed behaviour, follow "When you delete dead code" in the
   `git-commit` skill. A test that reaches live behaviour through the
   removed code moves to the live path with every assertion.
5. For a test on the "never" list, check whether it also checks the
   product. Move each product assertion to a test of its requirement
   first. When no test runs a CI script that the test read, add one that
   runs it.
6. Delete the test and each helper or fixture that only it used.
7. Run the deletion audit of the `git-commit` skill. Record each removal
   in the commit or the pull request description: the test, the reason,
   the covering test, and the proof file.

## Ports

A port replaces a test with a test in another language or at another
level. The old test is a duplicate when the port covers each of its
requirements. Prove the cover for each requirement with step 3. A port
that keeps every assertion can still lose a check. Examples are a final
newline in a snapshot, or a platform that only the old test ran on.

## Ask the user

- The test is the last test of a requirement.
- No kept test fails when you break the code.
- The covering test is at a higher level, for example a browser spec that
  would cover a unit test.
- The test is slow or low value, but no reason in the `testing` skill
  holds. You can make a slow test faster without asking.

When you ask, state what the test protects and how long it runs.

## Example

In one repository, 43 test files ran each case twice, once for each of two
modes. A later change removed the setting that made the two modes differ,
so each second run repeated the first. Removing the repeats cut 1,072
tests to 557 and the test time from about 325 to 189 seconds. Four files
kept both runs, because their two modes still read different data.

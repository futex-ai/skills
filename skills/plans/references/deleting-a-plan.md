# Deleting a plan

The pull request of a change deletes its plan, so that a plan does not stay
on `main` after its work merges. The protocol docs keep the decisions in
force. The pull request description keeps the dated record, and its
permalink keeps the full plan.

## When

The last two milestone TODOs of a plan delete it and open the pull
request. Do them when every other milestone TODO is ticked and the review
rounds are done. The tasks under `## Post-merge follow-up (non-blocking)`
are not milestone TODOs, so they do not hold back the deletion. Delete the
plan in the last commit before you open the pull request.

Keep the plan in these cases:

- The user asks for the pull request before the work is complete. Open
  it, and keep the plan. Delete the plan in the last commit of the work,
  when the condition above holds.
- The work spans more than one pull request. Each earlier pull request
  keeps the plan. The last one deletes it. Each earlier pull request gives
  a status line to each doc whose behaviour a later one builds. The
  `documentation` skill gives the status line.

## Steps

1. Turn each unchecked post-merge task, and each open item that has no
   file yet, into a follow-up item. Follow "Writing an item" in
   [follow-up-items.md](follow-up-items.md). Read the whole entry and
   each entry that it names. Keep every fact. Merge an entry into the
   item of the entry that covers it.
2. Check that the protocol docs hold each decision in force. Move content
   that works as a doc, such as a roadmap, to its home under the
   `documentation` skill.
3. Search `docs/`, `plans/`, and every `README.md` for links to the plan.
   A status line gets no permalink. Update it as the `documentation`
   skill says. Replace each other link with a permalink to the plan at
   the commit before the deletion. The `git-commit` skill says how to find
   that commit after a squash merge.
4. Delete the plan, and name it in the commit message.
5. Write the pull request description with the `git-commit` skill. It
   gives each user decision and design call of the plan with its date. It
   links to the plan with a permalink at the commit before the deletion.

## After the deletion

- Record each decision that comes after the deletion in the pull request
  description.
- When large new work comes after the deletion, restore the plan from the
  commit before the deletion. Delete it again when the work is done.
- Do not delete a completed plan that is already on `main` without the
  user's approval.

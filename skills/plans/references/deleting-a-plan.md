# Deleting a plan

The pull request of a change deletes its plan, so that a plan does not stay
on `main` after its work merges. The protocol docs keep the decisions in
force. The pull request description keeps the dated record, and its
permalink keeps the full plan.

## When

Delete the plan when every other TODO is ticked and the review rounds are
done. Do it in the last commit before you open the pull request. When the
work spans more than one pull request, the last one deletes the plan.

## Steps

1. Turn each unchecked post-merge task, and each open item that has no
   file yet, into a follow-up item.
2. Check that the protocol docs hold each decision in force. Move content
   that works as a doc, such as a roadmap, to its home under the
   `documentation` skill.
3. Search `docs/`, `plans/`, and every `README.md` for links to the plan.
   Replace each link with a permalink to the plan at the commit before the
   deletion. The `git-commit` skill says how to find that commit after a
   squash merge.
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

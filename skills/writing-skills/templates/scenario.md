---
skill: <the skill under test, the directory name>
variants: control skill
expect: <a regular expression that a pass shows in the agent's text or commands>
forbid: <a regular expression that a failure shows>
---
<The prompt that the agent gets, as a user would write it. Put the
pressures here: the deadline, the sunk cost, the authority, the plausible
shortcut. Describe the workspace that setup.sh builds, as a user would.
When a check.sh exists beside this file, it decides the hint from the
workspace state after the run, and the expect and forbid lines are not
used.>

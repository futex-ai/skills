# Models for delegation

This skill names no model id. Do not take a model id from memory. Take
it from the state file, which the first cycle fills from the favourites.
The user keeps the models of the coordinator's roles as favourites in
Conductor. `conductor model` lists every agent's model ids and efforts,
and then the favourites table. The Conductor environment prompt ranks the
model families from least to most capable.

## Resolve the roles

Resolve the roles in the first cycle. Record them in the state file, and
name them in the first status report, so that the user can correct them.
When the user changes a role in a message, update the state file.

| Role | Favourite | Effort | Use |
| --- | --- | --- | --- |
| `default` | The first Claude favourite. | `max` | Plans, plan reviews, investigations, goal reviews, and second opinions. |
| `implementation` | The first Codex favourite. | `max` | The implementation of a reviewed plan. |
| `complex` | The most capable Codex favourite, by the family ranking. The `implementation` model when there is one Codex favourite. | `max` | Many files, a migration, concurrency, or a design that the plan review calls unclear. |
| `routine` | A small Claude model from the model list, not a favourite. | `low` | The wake routine only. It runs a few commands. |

When the favourites table is empty, ask the user for the three models in
the status report, and delegate nothing until the user answers.

## Pass them on

- `conductor workspace create --agent <agent> --model <id> --effort max`
  for a new workspace.
- `conductor session create --workspace <id> --agent <agent> --model <id> --effort max`
  for a session in an existing workspace.
- Use `--effort max` for every role except `routine`.

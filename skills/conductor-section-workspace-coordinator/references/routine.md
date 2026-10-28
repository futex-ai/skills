# The wake routine

A Conductor cloud workspace sleeps when it is idle, and in any case after
about 24 hours. A Conductor routine is a saved prompt that runs in a fresh
workspace of its project each time its trigger fires. One routine per
project, named `coordinator wake`, wakes every coordinator of the project
once an hour. It finds each workspace named `coordinator: …`, reads the
status of the session named `coordinator`, and sends the wake message when
the session is idle. The prompt is
[templates/routine-prompt.md](../templates/routine-prompt.md).

## Limits

- Routine commands need a user API key. The key that a workspace holds is
  rejected with "Routine management requires a user API key". The user
  can give the coordinator workspace a key with
  `--env CONDUCTOR_API_KEY=<key>` at creation, or in the workspace
  settings.
- The CLI and the API create a routine with a webhook trigger only. An
  hourly trigger, a cron trigger, is set in the Conductor app. The user
  adds it to the routine, or an external scheduler posts to the webhook
  URL every hour.
- The webhook URL is the routine's only credential. It appears once, in
  the output of `routine create`. Save it under `.context/coordinator/`
  and never in a commit, a plan, a pull request, or a message.

## Ensure the routine

1. Run `conductor --json routine list --limit 100`.
2. When the command fails for the key: ask the user once, in the status
   report, to create the routine in the app from the prompt template, with
   the model of the `wake routine` action and an hourly trigger, or to
   give this workspace a user API key. Set `Routine: waiting for the user since
   <date>` in the state file. Repeat the request in each status report
   while it waits.
3. When the list holds `coordinator wake` for this project: set
   `Routine: confirmed on <date>`.
4. When it does not: create it with `conductor --json routine create
   --name "coordinator wake" --project-id <project id> --agent <agent>
   --model <id> --effort <level> --prompt-file <template path>`, with the
   agent, the model, and the effort of the `wake routine` action.
   Save the webhook URL under `.context/coordinator/routine-webhook-url`.
   Ask the user, in the status report, to add an hourly trigger in the
   app, or to post to the URL every hour from a scheduler. Set `Routine:
   created on <date>, trigger waiting for the user`.
5. A cycle that starts with a message that begins with `[coordinator
   wake]` proves that the routine runs. Set `Routine: confirmed on
   <date>`.

## The wake message

The routine sends `[coordinator wake] continue: run one coordinator cycle
and report the status.` A cycle that this message starts is an ordinary
cycle. When nothing changed, the status report says so in one line.

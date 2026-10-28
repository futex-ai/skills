You are the wake routine for the section workspace coordinators of this
project. Change no file. Do these steps, then report one line per
coordinator.

1. Read this project's repository: `conductor --json workspace get` gives
   `repoUrl`.
2. List the coordinators:
   `conductor --json workspace list --mine --name "coordinator: " --limit 100`.
   Page with `--offset` while `hasMore` is true. Keep the workspaces whose
   `repoUrl` is this project's repository.
3. For each coordinator, list its sessions:
   `conductor --json workspace session <workspace id> --limit 100`.
   Page with `--offset` while `hasMore` is true. Take the last session
   named `coordinator`. When none has that name, take the last session.
   Skip a coordinator without a session, and say so.
4. Read the session status: `conductor --json session status <session id>`.
   When the status is `working`, skip it and say so.
5. Send the wake message:
   `conductor message create --session <session id> --message "[coordinator wake] continue: run one coordinator cycle and report the status."`
6. Report one line per coordinator: the workspace name, the session id,
   and `sent`, `working`, or `no session`.

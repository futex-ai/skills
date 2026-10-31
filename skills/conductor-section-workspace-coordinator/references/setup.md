# First cycle: set up

Run these steps once, when `.context/coordinator/state.md` does not
exist. A restart with the state file skips them.

1. Find the section with `scripts/section-workspaces.sh`. It reads every
   page of the section list and prints the section whose `workspaceIds`
   holds `CONDUCTOR_WORKSPACE_ID`. When it finds none and the user named
   a section, move this workspace into it with
   `conductor workspace move --section <id>`. Create the section with
   `conductor section create <name>` when it does not exist. When no
   section is known, ask the user and stop.
2. When another workspace in the section is named `coordinator: …`, stop
   and report it. A section has one coordinator.
3. Rename this workspace with
   `conductor workspace rename --name "coordinator: <section name>"`.
   Rename this session with
   `conductor session rename $CONDUCTOR_SESSION_ID --name coordinator`.
   The routine and the section scan look for these names.
4. Create `.context/coordinator/state.md` from
   [templates/state.md](../templates/state.md). Record the goals and the
   metrics from the user's message, or `None`.
5. Ensure the wake routine, as [routine.md](routine.md) says.
6. Run a cycle.

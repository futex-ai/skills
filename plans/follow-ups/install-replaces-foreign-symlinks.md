# Install replaces a foreign symlink without backup

- **Severity:** Low. **Effort:** Medium. **Confidence:** High. **Harder later:** No.
- **Kind:** Outside the scope.
- **Added:** 2026-11-02, from the branch `conductor/agents-md-skills`. The docs implementor found it while it checked the facts of the new root `AGENTS.md`.
- **Location:** `scripts/install.sh`, the function `link()` at lines 83 to 103, and the functions `unlink_if_ours()` and `prune_dangling()` at lines 105 to 122. `README.md`, the section "Install", lines 124 and 125. `tests/install_test.sh`.
- **Reason:** The fix changes what `install.sh` does to a path that the user owns, and the branch that found it only adds `AGENTS.md`.

- **Terms:**
  - **Managed path:** a path where `scripts/install.sh` puts a symlink. These are each skill under `~/.claude/skills/` and `~/.agents/skills/`, and under `~/.codex/skills/` after `--codex-home`, and the rules files `~/.claude/CLAUDE.md` and `~/.codex/AGENTS.md`.
  - **Foreign symlink:** a symlink at a managed path whose target is outside the clone that runs `install.sh`. An example is a user's own `~/.claude/CLAUDE.md` that points into a dotfiles repository.
- **Background:**
  - `scripts/install.sh` links each skill directory and `global/AGENTS.md` of its clone into the agent directories. `scripts/update.sh` runs it again after each update, from a loop or from Claude Code hooks.
  - `link()` has three cases. A path that is not a symlink is skipped, unless `--force` first moves it to `<path>.bak`. A missing path gets a new symlink. A path that is a symlink is deleted and linked again, whatever its target.
  - `unlink_if_ours()`, which `--uninstall` uses, and `prune_dangling()` touch a symlink only when its target is inside the clone. `test_removes_dangling_links_into_the_repository_only` in `tests/install_test.sh` checks this for pruning.
  - `README.md` says: "The script skips a path that exists and is not a symlink; pass `--force` to replace it (the original is kept as `.bak`)." It says nothing about a path that is already a symlink.
  - `link()` has replaced every symlink since the first commit, `f3b7e52`.
- **Problem:** `link()` replaces a foreign symlink without `--force` and keeps no backup. Its output line says `linked <path>` and does not name the old target. A later `--uninstall` removes the new symlink and does not bring back the old one.
- **Impact if no action:** A user who keeps `~/.claude/CLAUDE.md`, `~/.codex/AGENTS.md`, or a skill directory as a symlink to their own files loses that link on the first install. Their own rules or skill stop loading, and nothing records where the link pointed. The target files stay on disk.
- **Root question:** What should `install.sh` do with a symlink at a managed path whose target is outside its clone?
- **Options:**
  - **A.** Change nothing in the code. Add one sentence to `README.md` "Install": the script replaces any symlink at a managed path. The user still loses the link without notice. Effort: Small.
  - **B.** Replace a foreign symlink, and print its old target in the output line, so that the user can restore it. Add a test to `tests/install_test.sh`. Update the README sentence. The link is still replaced. Effort: Small.
  - **C.** Treat a foreign symlink like a regular file. Skip it with a message, and with `--force` move it to `<path>.bak` first. Add a test and update the README. A clone that moved, or a second clone, then needs `--force` once, because its old symlinks point outside the new clone. Effort: Small.
  - **D.** Replace a foreign symlink only when its target is a skill directory or a `global/AGENTS.md` of another clone of this repository, which covers a moved clone. Skip every other symlink, as C does. Add tests for both cases and update the README. Effort: Medium.
- **Left out:** A prompt that asks the user before the replacement. `update.sh` runs `install.sh` unattended from a loop and from hooks, so nobody can answer it.
- **Wider fix:** C. One rule for every path that the script does not own removes the case. D is the same rule with an exception for a moved clone.
- **Previous examples:** None found. `prune_dangling()` and `unlink_if_ours()` already protect a foreign symlink.
- **Recommendation:** D. It protects the user's own links and keeps the relink of a moved clone without `--force`. C best protects the codebase, because it has no exception to maintain.
- **Action:** ask the user, because C and D change what the script does to a path that the user owns, and no requirement covers a foreign symlink.

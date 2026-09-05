---
name: jean-zay-sync
description: Use the existing Jean Zay (Jean-Zay, JZ) cluster workflow for connecting, SSHFS mounts, local-to-remote synchronization, and remote work with jzstart. Use when the user mentions Jean Zay, JZ, jzstart, jzmount, or jzrsync in a cluster workflow.
---

# Jean Zay sync

Use the existing helpers in `~/configuration/remote_scripts/`. Read the relevant
scripts before starting or troubleshooting; do not recreate their workflow.
For configuration details, read the remote workflow section of
`~/configuration/README.md`. Keep private connection values in local configuration.

## Start the workflow

`jzstart [LOCAL_DIR] [SUBPATH_UNDER_WORK]` is the setup and sync entry point.
The alias lives in `.zshrc`; in an agent shell invoke the script directly:

```bash
~/configuration/remote_scripts/start_jz.sh /path/to/local/project projects/example
```

LOCAL_DIR defaults to the current directory. Without the second argument, the
remote subpath is derived from LOCAL_DIR relative to HOME, under remote WORK.
For sources outside HOME, supply a remote subpath. Read the resolved destination
from the logs. Inspect the source and check for an existing watcher before
starting; keep the running session available while synchronization is needed.

## Understand the three parts

1. SSH opens or reuses a master connection for remote commands and transfers.
2. SSHFS refreshes local mounts that expose live remote files. Writes through
   these mounts change remote files directly. They are not the source checkout.
3. Rsync copies the local checkout to remote WORK over SSH, independently of
   SSHFS. Fswatch repeats the copy after local changes. No compute job is submitted.

When the source contains a `.git` **directory**, `git ls-files` selects paths.
Rsync copies current working-tree contents, including uncommitted edits and
staged new files. Untracked files are excluded. Git metadata is also copied,
excluding lock files. This is not a Git push or a checkout of committed content;
no commit is needed to synchronize edits to an existing tracked file.

The Git filter does not apply to repository subdirectories or linked worktrees
with a `.git` file. These fall back to copying the whole source tree, including
untracked and ignored files. Check the logged scope before relying on filtering.

Edit the local source. Remote changes do not sync back and may be overwritten.
Rsync does not delete remote files, so local deletions or renames can leave stale
remote files. New untracked files need intentional inclusion in Git's index or
a separate transfer; do not silently stage unrelated files.

## Interpret logs and completion

- `event=sync_scope` describes actual file selection.
- `event=initial_sync_complete` confirms the first copy succeeded.
- `event=handoff` only transfers control to the sync helper.
- `event=watch_start` announces watcher startup, not a health check. Idle watching
  can be silent; do not treat the long-running process as a hung command.
- After later edits, check `event=sync_complete` and verify relevant remote files
  before running work that depends on them.
- Inspect `event=failed`, its stage and exit code, and underlying command errors.
  Authentication/sudo fields indicate possible interaction, not an active prompt.

Mount helpers can report success despite individual errors. Verify mount state
when the task depends on SSHFS. Ctrl-C stops synchronization but leaves SSHFS
mounts and the SSH master in place. Use the existing mount/unmount helpers when
that is part of the requested task.

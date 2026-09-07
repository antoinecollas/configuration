---
name: jean-zay-sync
description: Synchronize local code and remote outputs with Jean Zay (Jean-Zay, JZ) using jzsync and Mutagen. Use for Jean Zay development, automatic result downloads, sync status, or SSHFS access.
---

# Jean Zay sync

Use `jzsync [LOCAL_DIR] [SUBPATH_UNDER_WORK]`. It is an executable on PATH,
not a shell alias. If the command is unavailable, invoke
`~/configuration/scripts/jzsync` directly. When troubleshooting, read that script
and `~/configuration/remote_scripts/mutagen.yml`.

The local directory defaults to the current directory. The remote subpath defaults
to the local path relative to HOME under remote WORK. Sources outside HOME require
an explicit subpath. The command reuses the SSH master or opens it with
`ssh -MNf jz`; authentication may need user interaction. Keep the master open
for subsequent remote commands and shared Mutagen sessions.

## Data flow

Mutagen runs in the background: local code goes to Jean Zay; remote outputs return
automatically, including untracked files and plots beside scripts. It deliberately
does not use `.gitignore`, which may exclude outputs the user wants.

The shared YAML excludes `.cache`, `data`, `.git/**/*.lock`, `.venv`,
`__pycache__`, `.DS_Store`, and `.env` files in both directions. Never remove these
exclusions just to obtain a result. Export selected results outside `.cache` when
needed.

For regular checkouts, `.git` syncs both ways in the same session as the working
tree. Git lock files are excluded. Avoid concurrent Git writes on both sides;
flush and check for conflicts before switching sides. This is file synchronization,
not an atomic Git operation. Linked worktrees/submodules with a `.git` file are
rejected: use a clone. Compare HEAD and working-tree status after flushing; matching
HEAD alone does not prove uncommitted code matches. Use diffs or hashes as needed.

`two-way-safe` reports conflicting edits, but nonconflicting edits and deletions
can propagate in either direction. Edit code locally; inspect conflicts before
choosing a version. Do not force a reset or switch the code/output session to replica mode to clear errors.

## Agent operation

- The command prints a project file under `~/.cache/jean-zay-sync`. Use that file
  with `mutagen project list|flush|pause|resume|terminate -f <project-file>`.
- Before submitting a job, flush and inspect status for conflicts or scan errors.
  Flush completion alone does not prove every file is conflict-free.
- Sessions survive terminal/Codex exit. Reuse the existing project; do not create
  a second manual session or terminate shared sync when your task ends.
- A destination is pinned to its local source and policy. Exit 75 means a mismatch;
  inspect the printed project file instead of overwriting it.
- Independent agents use separate checkouts and disjoint remote directories.
  Parent/child overlaps and sessions on other machines are not automatically
  prevented. Manage by project file or session ID, not a potentially repeated name.
- Remote files are polled every 1 second, including outputs written by compute
  nodes on the shared filesystem. No compute job is submitted by jzsync.

SSHFS is optional and independent: use `mount_jz.sh` to browse live remote files.
Do not unmount shared paths as routine cleanup. Mutagen does not need SSHFS.

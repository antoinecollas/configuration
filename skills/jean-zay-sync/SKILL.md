---
name: jean-zay-sync
description: Sync a local checkout with Jean Zay using jzsync and Mutagen, keep remote outputs returning automatically, and troubleshoot sync sessions. Use for Jean Zay code transfers, sync-and-run tasks, output downloads, or SSHFS access; use project instructions for job submission.
---

# Jean Zay sync

Use `jzsync` to keep local code and remote outputs synchronized over SSH.
It starts or resumes a persistent Mutagen project, flushes changes, and prints
status. Remote GitHub access is not required.

## Sync the checkout

Choose the local checkout and remote destination from the task and project
instructions. Inspect local Git status before starting, since remote changes can
return locally. Use a standalone clone: linked worktrees and submodules with a
`.git` file are unsupported.

```bash
jzsync <local-checkout> <relative-path-under-remote-WORK>
```

The command is an executable on PATH. If unavailable, use
`~/configuration/scripts/jzsync`. With no arguments it uses the current directory
and its path relative to HOME under remote WORK. For example,
`jzsync ~/projects/example` targets `$WORK/projects/example` on Jean Zay.
Paths outside HOME need an explicit remote subpath.

Run the command even when no Mutagen sessions exist; it creates the project.
Remote untracked files are normal and eligible files return locally. Matching
Git commits do not replace working-file and output synchronization.

Save the resolved destination and project-file path printed by `jzsync`.
The project file lives under `~/.cache/jean-zay-sync`. Use that exact file for
later operations, rather than a session display name that may be shared.

## Verify, then run

Inspect the status printed by `jzsync`. Resolve conflicts or scan errors before
running code. A successful flush alone does not establish that all files match.
For Git checkouts, compare HEAD and working-tree status on both sides; inspect
diffs or hashes when needed to verify uncommitted code.

For later edits or a final check before submitting jobs:

```bash
mutagen project flush -f <project-file>
mutagen project list -f <project-file>
```

When the user also requested execution, continue with the target project's
instructions for the environment, feature caches, resources, and job submission.
`jzsync` submits no jobs. Prepare missing caches on the cluster and export desired
results outside excluded directories so they can return automatically.

Leave synchronization running when the task ends. Sessions survive terminal and
Codex exit. The remote endpoint polls every second to discover compute-node
outputs on the shared filesystem. Keep the SSH master open for shared sessions
and later remote commands.

## Understand what can change

The policy is `two-way-safe`: files and nonconflicting edits or deletions can
propagate in either direction. Edit code locally and inspect conflicting versions
before resolving them. Do not clear conflicts with a forced reset or replica mode.
`.gitignore` is deliberately not used, so untracked plots and logs can sync.

Regular checkouts include `.git` in the same session as the working tree.
Avoid simultaneous Git writes on both sides; flush and inspect status before
switching sides. File synchronization is not an atomic Git operation.

The shared policy excludes `.cache`, `data`, `.venv`, `__pycache__`, `.DS_Store`,
`.env`, `.env.*`, Git lock files, `.git/worktrees`, and `.git/config.worktree`.
Excluded paths, including remote cache/data symlinks, stay untouched. Keep these
exclusions; copy selected results to an included output directory instead.

Reuse the existing project for the same endpoints. Independent agents need
separate clones and disjoint remote directories. The wrapper does not prevent
parent/child overlaps or sessions started on another machine.

## Troubleshoot only when needed

Read `~/configuration/scripts/jzsync` and
`~/configuration/remote_scripts/mutagen.yml` when diagnosing a failure.

| Symptom | Next action |
| --- | --- |
| Mutagen is missing | Install with `brew install mutagen-io/mutagen/mutagen`. |
| SSH authentication is needed | Let `jzsync` open its SSH master with `ssh -MNf jz`; complete interactive authentication if required. |
| Remote WORK cannot be resolved | Check that the remote login shell exposes an absolute `WORK` and provides `realpath`. |
| Exit 75: source or policy mismatch | Inspect the printed project file and its endpoints. Reuse the intended source or choose a disjoint destination; do not overwrite the pinned configuration. |
| Session is paused | Run `mutagen project resume -f <project-file>`, then flush and inspect status. |
| Conflicts or scan errors | Inspect the affected paths and versions, fix the cause, then flush and check again. |

Diagnose an actual `jzsync` failure before choosing another transfer method,
unless the user requested one. A Git pull or bundle alone does not keep outputs
returning automatically. Do not create duplicate manual sessions or terminate
shared projects as routine cleanup.

For live remote browsing, use `mount_jz.sh` (shell alias `jzmount`). SSHFS is
independent of Mutagen. Do not unmount shared paths as routine cleanup.

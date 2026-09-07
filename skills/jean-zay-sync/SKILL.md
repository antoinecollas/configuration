---
name: jean-zay-sync
description: Copy local code to Jean Zay with jzsync (one-way rsync), optionally watch local changes with fswatch, and retrieve selected remote results. Use for Jean Zay code transfers and sync-and-run tasks; use project instructions for job submission.
---

# Jean Zay sync

Use `jzsync` to copy local code to Jean Zay over SSH. For a Codex sync-and-run
task, make one transfer and wait for it to finish:

```bash
jzsync --once <local-checkout> <relative-path-under-remote-WORK>
```

The command is on PATH; otherwise use `~/configuration/scripts/jzsync`.
Choose the checkout and destination from the task and project instructions.
With no path arguments, it uses the current directory and its path relative to
HOME under remote WORK. Paths outside HOME need an explicit remote subpath.
It reuses or opens an SSH master; remote GitHub access is not needed.

## Copy, then run

Inspect local changes, run `jzsync --once`, and wait for exit code 0 and
`[jz] Sync complete.` before submitting jobs. On failure, fix the reported SSH,
path, or rsync error and retry. If the execution sandbox blocks the command,
request the required execution approval and retry the same command.

Git checkouts copy tracked files with their current local contents, including
uncommitted edits. New files must be staged with `git add` to be included.
The file list is rebuilt on each transfer. Linked worktrees are supported;
submodule contents are not copied automatically. Non-Git directories copy all
files except the exclusions below.

`.git`, `.cache`, `data`, `.venv`, `__pycache__`, `.DS_Store`, `.env`, and `.env.*`
are excluded. Remote files with matching included paths are overwritten, but
remote files are never deleted. Renamed or deleted local files can therefore
leave stale remote files. Use a fresh destination when an exact file set matters.
Git metadata is not copied: verify relevant file contents when needed, rather
than expecting remote HEAD or Git status to match.

Continue with the target project's environment, cache, and job instructions.
`jzsync` does not submit jobs. Independent checkouts need disjoint destinations.

## Watch while editing

Omit `--once` for an initial copy followed by an `fswatch` loop:

```bash
jzsync <local-checkout> <relative-path-under-remote-WORK>
```

Keep it running in a terminal or managed execution session. Each successful
transfer prints `Sync complete.`; errors stop the command. Stop the watcher with
Ctrl-C. It is a foreground process, with no daemon or project state. Use one
watcher per destination, and stop it before changing the branch being executed.
`JZ_FSWATCH_LATENCY` sets batching latency (default: 1 second).

## Retrieve results

Results stay on Jean Zay. Use `scp` or a separate remote-to-local `rsync` command
to download the specific files requested by the user. Use a local results folder
to avoid overwriting source files. Remote caches and data remain in place.
For live browsing, use `mount_jz.sh` (`jzmount`); do not unmount shared paths as
routine cleanup.

## Setup

Install local tools with `brew install rsync fswatch`. Both endpoints need rsync
with `--protect-args` support; the remote login shell must expose an absolute
`WORK` and provide `realpath`. `--once` does not require fswatch.

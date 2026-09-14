---
name: cluster-sync
description: Sync local code to Jean Zay (jean-zay, jz) or LUMI (lumi) with jzsync or lumisync, watch edits, and retrieve selected results over SSH and rsync. Use for cluster code transfers and the transfer part of sync-and-run tasks; use the target repository's instructions for job submission.
---

# Code sync for Jean Zay / jz and LUMI

Choose the cluster requested by the user. Reuse the established SSH alias,
checkout and destination; do not infer them from the current local directory alone.
Both commands use the shared [hpcsync implementation](../../scripts/hpcsync).

| Cluster | Command | Remote workspace root | Watch latency |
| --- | --- | --- | --- |
| Jean Zay / jean-zay / jz | `jzsync` | Remote `WORK`, or local `JZ_WORK` override | `JZ_FSWATCH_LATENCY` |
| LUMI / lumi | `lumisync` | Local `LUMI_WORK`, required | `LUMI_FSWATCH_LATENCY` |

Keep personal host/path settings in `~/.zshrc.local`. `LUMI_WORK` is the user's
code workspace root, not necessarily the shared project root. Commands are on
PATH, or available under `~/configuration/scripts/`.

## Copy, then run

Inspect local and remote edits before a transfer. Use a personal destination;
never overwrite a colleague's checkout. For an authorized sync-and-run task,
make one transfer and wait for completion:

```bash
jzsync --once <local-checkout> <relative-subpath>
# Or, for LUMI:
lumisync --once <local-checkout> <relative-subpath>
```

The local directory defaults to the current directory. The remote subpath defaults
to its path relative to local HOME under the selected workspace root. Paths outside
HOME need an explicit relative subpath. Each host uses its own SSH master.

Wait for exit code 0 and `[jz] Sync complete.` or `[lumi] Sync complete.` before
launching anything. Report SSH authentication/proxy errors instead of treating
an incomplete transfer as success. Continue with the repository's run skill;
these helpers do not submit jobs.

Git checkouts copy tracked files with their current contents, including local
edits. New files must be staged to be included; otherwise transfer the specifically
requested new files separately. Do not stage unrelated work just to sync it.
Linked worktrees are supported; submodule contents are not copied automatically.
Non-Git directories copy all files except the same exclusions.

`.git`, `.cache`, `data`, `.venv`, `__pycache__`, `.DS_Store`, `.env`, and `.env.*`
are excluded. Inspect the actual file list when logs or results are inside the
checkout: the helper does not exclude every possible output directory.

Transfers overwrite matching included files but never delete remote files.
Renames/deletions can leave stale files; use a fresh destination when an exact
file set matters. Git metadata is not copied: verify file contents or hashes,
rather than expecting remote HEAD to represent the transferred edits. Use a
separate Git bundle when an exact Git checkout is required.

## Watch and retrieve

Omit `--once` to watch with fswatch. The latency defaults to one second. Use one
watcher per destination; stop it with Ctrl-C before switching the executed branch.
The watcher runs in the foreground and stops on errors.

Results stay remote. Retrieve the requested files with narrow `scp` or rsync
commands into a local results directory. Leave remote data/caches intact.
Jean Zay also has `jzmount` / `jzumount` for optional browsing; do not assume
those helpers support LUMI or unmount another process's paths.

## Requirements

Local tools: `ssh`, `git`, `rsync`, and `fswatch` for watch mode. On macOS,
`brew install rsync fswatch` provides the latter two. Both endpoints need rsync
with `--protect-args`. Remote Bash must have `realpath` and an absolute workspace
root; Jean Zay's login environment supplies WORK unless locally overridden.

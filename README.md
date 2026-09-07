# configuration

Personal dotfiles and developer configuration for shell, editor, Codex, and remote HPC workflows.
This repo is optimized for day-to-day reuse on macOS, with machine-specific overrides kept out of version control.

## Contents

- [Repository layout](#repository-layout)
- [Quick start](#quick-start)
- [Prerequisites](#prerequisites)
- [Shell configuration](#shell-configuration)
- [Remote scripts (Jean-Zay workflow)](#remote-scripts-jean-zay-workflow)
- [Remote scripts (VM workflow)](#remote-scripts-vm-workflow)
- [Neovim setup](#neovim-setup)
- [Troubleshooting](#troubleshooting)
- [Usage note](#usage-note)

## Repository layout

| Path | Purpose |
| --- | --- |
| `.zshrc` | Main Zsh config (aliases, prompt, helper functions, conda init, and tool PATHs). |
| `.tmux.conf` | Tmux configuration with mouse support enabled. |
| `.zshrc.local.example` | Template for local machine overrides. |
| `scripts/` | Small personal CLI helpers available from the shell. |
| `skills/` | Personal Codex skills, symlinked into `~/.codex/skills`. |
| `remote_scripts/` | SSHFS mount/unmount and rsync helpers for remote cluster workflows. |
| `nvim/` | Neovim config (`init.lua`) and lockfile (`lazy-lock.json`). |
| `jz_configuration/` | Additional cluster shell startup files (`.bashrc`, `.bash_profile`, `.zshrc`). |
| `starship.toml` | Starship prompt configuration. |
| `generate_single_file.py` | Helper script that exports tracked source context into one Markdown file. |

## Quick start

```bash
git clone https://github.com/<your-user>/configuration.git ~/configuration
cd ~/configuration
```

Example symlink setup:

```bash
ln -sf ~/configuration/.zshrc ~/.zshrc
ln -sf ~/configuration/.tmux.conf ~/.tmux.conf

mkdir -p ~/.config/nvim
ln -sf ~/configuration/nvim/init.lua ~/.config/nvim/init.lua
```

Create local overrides:

```bash
cp ~/configuration/.zshrc.local.example ~/.zshrc.local
```

## Prerequisites

Required: `zsh`, `git`, `ssh`, `rsync`.

For Jean Zay sync: `mutagen`. For mounting: `sshfs`. The VM sync helper uses `fswatch`.

Optional: `nvim`, Conda, Jupyter (`nbconvert`), `starship`, `zsh-autosuggestions`.

## Shell configuration

### Main shell file (`.zshrc`)

- Limits BLAS/OMP thread count to `1`.
- Loads host-specific additions from `~/.zshrc.local`.
- Adds `~/configuration/scripts` to `PATH`.
- Adds `~/configuration/remote_scripts` to `PATH`.
- Defines alias: `gs` -> `gh stack`.
- Defines aliases: `jzmount` -> `mount_jz.sh`, `jzumount` -> `umount_jz.sh`.
- Exposes `jzsync` as an executable from `~/configuration/scripts`, including in
  non-interactive shells that inherit this PATH.
- Defines alias: `vmrsync` -> `vmrsync.sh`.
- Includes helper functions: `open_notebook` (convert/open notebook PDF), `wt` (create worktree + launch codex), `wtrm` (remove worktree + local branch).
- Includes the conda initialization block managed by `conda init`.
- Enables Starship prompt and `zsh-autosuggestions`.

### Local overrides (`.zshrc.local`)

Use this for anything machine- or identity-specific:

- private hostnames
- user IDs
- local paths
- Jean-Zay variables (`JZ_USER`, `JZ_HOME`, `JZ_WORK`, `JZ_SCRATCH`)
- tokens/secrets

`~/.zshrc.local` is intentionally ignored by Git.

### Personal CLI helpers

This repo now exposes `build_database_url` as a global shell command.

Example:

```bash
build_database_url \
  --username my_user \
  --host localhost \
  --port 5432 \
  --database my_db
```

If `--password` is omitted, the command prompts with `DB password:`.

After reloading your shell, it will be available anywhere because
`~/configuration/scripts` is added to `PATH`.

If you pass `--protocol postgres`, the helper rewrites it to
`postgresql`.

Use `build_database_url --help` to see the built-in helper text.

## Remote scripts (Jean-Zay workflow)

Edit locally, run code on Jean Zay, and receive remote outputs automatically.
[Mutagen](https://mutagen.io/documentation/introduction/getting-started/) manages
persistent background synchronization; SSHFS is a separate tool for browsing.

```bash
brew install mutagen-io/mutagen/mutagen
jzsync ~/projects/example
# Optional: override the destination under remote WORK.
jzsync ~/projects/example projects/example-agent-a
```

`jzsync` defaults to the current directory and derives the remote subpath from
its path relative to HOME. Paths outside HOME require an explicit subpath.
`jzsync` reuses an existing SSH master or opens one with `ssh -MNf jz`, using
your SSH configuration. This can prompt for authentication. The master remains
available for later Codex commands and Mutagen connections. The
remote shell must expose WORK and provide `realpath`; Mutagen installs its own
remote agent over SSH.

The implementation is small:

- `scripts/jzsync`: resolve endpoints, create or resume a Mutagen project,
  flush pending changes, and show status. Numbered comments explain each step.
- `remote_scripts/mutagen.yml`: shared synchronization policy.
- `remote_scripts/mount_jz.sh` / `umount_jz.sh`: explicit SSHFS mount management.

### What synchronizes

The policy uses **two-way-safe**: local code goes out and remote outputs come back,
including new files that are not tracked by Git. It does not use `.gitignore`,
which often excludes desired outputs such as PNGs, figures, and logs.

The session excludes `.cache`, `data`, `.git/**/*.lock`, `.venv`,
`__pycache__`, `.DS_Store`, `.env`, and `.env.*` at every level. Excluded paths
are neither copied nor deleted by that session. Outputs saved under `.cache` stay remote; export selected results
outside that directory to synchronize them.

This replaces the old tracked-files-only, one-way rsync behavior. Nonconflicting
remote code edits and deletions can also propagate back. Conflicting edits are
reported for resolution, not automatically overwritten.

For regular Git checkouts, `.git` synchronizes in both directions in the same
session as code and outputs. HEAD, refs, objects, and the index are included;
Git lock files and machine-specific `.git/worktrees` and `.git/config.worktree`
records are excluded. Existing remote symlinks under excluded directories
(`data`, `.cache`, `.venv`) are preserved.
Avoid simultaneous Git writes on both sides, and
flush before switching sides. File synchronization is not an atomic Git operation;
concurrent changes can cause metadata conflicts. Linked worktrees and submodules
with a `.git` file are rejected; use a standalone clone.

After flushing, inspect Mutagen status and compare `git rev-parse HEAD` and
`git status --short` on both sides. Matching HEAD alone does not prove that
uncommitted working-tree contents match; inspect diffs or file hashes as needed.
See [Mutagen sync modes](https://mutagen.io/documentation/synchronization/) and
[ignore rules](https://mutagen.io/documentation/synchronization/ignores/).

The remote endpoint polls every 1 second so files written by compute nodes can
be discovered through the shared filesystem. Use `flush` before submitting a job,
and inspect status for conflicts or scan errors.

### Sessions and parallel agents

The command prints the project file under `~/.cache/jean-zay-sync`. Manage that
specific project with:

```bash
mutagen project list -f <project-file>
mutagen project flush -f <project-file>
mutagen project pause -f <project-file>
mutagen project resume -f <project-file>
mutagen project terminate -f <project-file>
```

Sessions survive the terminal or Codex session closing. Do not terminate a shared
project as routine agent cleanup. Multiple agents using the same local checkout
and remote destination share one Mutagen project. An atomic configuration file
pins each resolved remote destination to one local source and policy; a mismatch
exits with code 75. Mutagen's project lock prevents duplicate project starts.

Independent agents need separate checkouts and **disjoint remote directories**.
Parent/child destination overlaps are not automatically blocked by this wrapper.
Different machines and manually created Mutagen sessions also need coordination.
Use project files or session IDs for management; session display names can repeat.

Policy changes apply to new sessions. To change an existing policy, inspect and
terminate the affected project, then remove its generated YAML file and rerun
`jzsync`. Do not remove active project lock files.

### SSHFS and Codex

Use `jzmount` only when live remote filesystem access is useful; `jzsync` does not
mount or unmount anything. Writes through SSHFS change remote files directly.
Avoid `jzumount` while another agent uses those mounts.

The [Jean Zay sync skill](skills/jean-zay-sync/SKILL.md) is tracked here and installed
for all projects through a symlink:

```bash
mkdir -p ~/.codex/skills
ln -s ~/configuration/skills/jean-zay-sync ~/.codex/skills/jean-zay-sync
```

Use `$jean-zay-sync` or mention Jean Zay. Edit the skill here; the symlink reads the
same file. Project-specific values and generated Mutagen state stay local.
The skill covers sync, verification, and troubleshooting; job submission follows
the target project's instructions.

## Remote scripts (VM workflow)

Files:

- `remote_scripts/vmrsync.sh`: one-way local -> remote sync, then continuous watch/sync

Expected setup:

- SSH access to your remote VM
- Remote machine has a writable home directory

Typical usage:

```bash
cd ~/path/to/project
vmrsync <ip-or-host>
```

This defaults to:

- local source: current directory
- remote destination: `~/work/<current-directory-name>`

Optional usage:

```bash
vmrsync <ip-or-host> ~/path/to/project custom-remote-subpath
```

Environment variables:

- `vmrsync` defaults to the remote user `root`
- `VM_FSWATCH_LATENCY`: optional `fswatch` latency override

Notes:

- `vmrsync.sh` syncs tracked Git files only when source is a Git repo.
- Non-Git mode syncs the whole directory except `.git`.
- Continuous mode uses `fswatch`; stop with `Ctrl-C`.

## Neovim setup

`nvim/init.lua` bootstraps `lazy.nvim` and configures:

- UI/theme and editor defaults, including a vertically centered cursor when possible
- Telescope search mappings, including scoped live grep via `<leader>sg` across hidden files and directories
- Treesitter highlighting
- LSP/completion via `mason.nvim`, `nvim-lspconfig`, `nvim-cmp`
- Git tools (`gitsigns`, `vim-fugitive`, `diffview`)
- Aerial outline pinned to the Neovim 0.11 compatibility branch
- Wrapped long lines with word-aware breaks
- Markdown rendering and filetype-specific behavior

`nvim/lazy-lock.json` pins plugin versions.

Scoped live grep examples:

```text
"TODO" -g "*.py"
"TODO" -g "nvim/**"
"TODO" -g "*.lua" -g "!lazy-lock.json"
```

In the live grep prompt, type a search term and press `<C-g>` to turn it into
`"search term" -g `. Then type the file glob.

When a live grep result is opened, the prompt is remembered. The next
`<leader>sg` starts with the same search text.

`<leader>sg` also searches hidden files and directories. Ignored paths such as
`.git`, `node_modules`, and `__pycache__` stay filtered from Telescope results.

## Troubleshooting

`jzsync`/`jzmount`/`vmrsync` fails:

- Verify SSH access works: `ssh <ssh-alias>` or `ssh <ip-or-host>`
- Verify required tools: `command -v sshfs fswatch rsync`

Aliases not found:

- Confirm the correct zsh config is sourced (`~/.zshrc`)
- Reload shell: `source ~/.zshrc`

Conda conflicts:

- Re-run `conda init zsh` and restart shell
- Keep only one conda init block active in your loaded config

Neovim plugin issues:

- Open Neovim and run `:Lazy sync`
- Check language server install status with `:Mason`

## Usage note

This is a personal configuration repo. Reuse ideas freely, but expect to adapt paths, aliases, and environment-specific assumptions.

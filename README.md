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

For continuous Jean Zay and VM sync: `fswatch`. For mounting: `sshfs`.

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

### Cluster Bash startup

`jz_configuration/.bashrc` loads `.bash_profile` for SSH commands.
When `WORK` is missing, `.bash_profile` starts a login shell to read the cluster
environment only if the current shell is not already a login shell. This prevents
recursive `bash -lc` calls that can hang SSH startup. An unset `WORK` also skips
the WORK tools directory in `PATH`. Interactive shells switch to Zsh when it is
available, or keep a Bash prompt with a warning if it is missing or inaccessible.
If `~/.local` is a symlink to project storage, check access to its target when
tools disappear.

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

`jzsync` copies local code to Jean Zay with rsync, then watches local changes
with fswatch. Use `--once` to copy and exit before submitting jobs.

```bash
brew install rsync fswatch
jzsync --once ~/projects/example
jzsync ~/projects/example projects/example-agent-a
```

The local directory defaults to the current directory. The destination defaults
to its path relative to HOME under remote WORK. Paths outside HOME need an
explicit subpath. The command reuses or opens an SSH master; the remote login
shell must expose WORK and provide `realpath`. Both endpoints need rsync with
`--protect-args` support.

Git checkouts copy tracked files, including local edits. Stage new files with
`git add` to include them. The file list is refreshed on each transfer. Linked
worktrees are supported; submodule contents are not copied automatically.
Non-Git directories copy all files except `.git`, `.cache`, `data`, `.venv`,
`__pycache__`, `.DS_Store`, `.env`, and `.env.*`. These exclusions also apply to
Git checkouts.

Transfers overwrite matching files but never delete remote files. Local deletions
and renames can leave stale remote files; use a fresh destination when needed.
Git metadata stays local. Results stay remote; download selected files with
`scp` or a separate rsync command.

Wait for `Sync complete.` and exit code 0 from `--once` before launching jobs.
Watch mode stays in the foreground until Ctrl-C; errors stop the command.
`JZ_FSWATCH_LATENCY` sets batching latency (default: 1 second).
Use one watcher per destination and disjoint destinations for separate checkouts.

Use `jzmount` / `jzumount` for optional SSHFS browsing. Avoid unmounting paths
used by another process.

The [Jean Zay sync skill](skills/jean-zay-sync/SKILL.md) is installed through a symlink:

```bash
mkdir -p ~/.codex/skills
ln -s ~/configuration/skills/jean-zay-sync ~/.codex/skills/jean-zay-sync
```

Use `$jean-zay-sync` or mention Jean Zay. Job submission follows the target
project's instructions.

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

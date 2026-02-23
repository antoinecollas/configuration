# configuration

Personal dotfiles and developer configuration for shell, editor, Codex, and remote HPC workflows.
This repo is optimized for day-to-day reuse on macOS and Linux, with machine-specific overrides kept out of version control.

## Contents

- [Repository layout](#repository-layout)
- [Quick start](#quick-start)
- [Prerequisites](#prerequisites)
- [Shell configuration](#shell-configuration)
- [Remote scripts (Jean-Zay workflow)](#remote-scripts-jean-zay-workflow)
- [Neovim setup](#neovim-setup)
- [Codex setup](#codex-setup)
- [Maintenance guidelines](#maintenance-guidelines)
- [Troubleshooting](#troubleshooting)
- [Usage note](#usage-note)

## Repository layout

| Path | Purpose |
| --- | --- |
| `.zshrc` | Linux-oriented Zsh config (threads, CUDA/Julia paths, conda init, aliases). |
| `.apple_zshrc` | macOS-oriented Zsh config (brew, prompt, aliases, helper functions). |
| `.zshrc.local` | Local machine overrides (not tracked by Git). |
| `remote_scripts/` | SSHFS mount/unmount and rsync helpers for remote cluster workflows. |
| `nvim/` | Neovim config (`init.lua`) and lockfile (`lazy-lock.json`). |
| `codex/` | Codex config, prompts, rules, AGENTS instructions, and reusable skills. |
| `jz_configuration/` | Additional cluster shell startup files (`.bashrc`, `.bash_profile`, `.zshrc`). |
| `starship.toml` | Starship prompt configuration. |
| `generate_single_file.py` | Helper script that exports tracked source context into one Markdown file. |

## Quick start

```bash
git clone https://github.com/<your-user>/configuration.git ~/configuration
cd ~/configuration
```

Pick your shell config by platform:

- Linux: use `~/.zshrc` from this repo.
- macOS: use `~/.apple_zshrc` from this repo.

Example symlink setup:

```bash
ln -sf ~/configuration/.zshrc ~/.zshrc
# or on macOS:
ln -sf ~/configuration/.apple_zshrc ~/.zshrc

mkdir -p ~/.config/nvim
ln -sf ~/configuration/nvim/init.lua ~/.config/nvim/init.lua
```

Create local overrides:

```bash
touch ~/.zshrc.local
```

## Prerequisites

Required: `zsh`, `git`, `ssh`, `rsync`.

For remote scripts: `sshfs` and `fswatch`.

Optional: `nvim`, Conda, Jupyter (`nbconvert`), `starship`, `zsh-autosuggestions`.

## Shell configuration

### Linux (`.zshrc`)

- Limits BLAS/OMP thread count to `1`.
- Defines common aliases (for example `ll`, Slurm helpers).
- Sets CUDA and Julia-related paths.
- Includes a conda initialization block managed by `conda init`.

### macOS (`.apple_zshrc`)

- Loads host-specific additions from `~/.zshrc.local`.
- Adds `~/configuration/remote_scripts` to `PATH`.
- Defines aliases: `jzmount` -> `mount_jz.sh`, `jzumount` -> `umount_jz.sh`, `jzrsync` -> `rsync_jz.sh`.
- Includes helper functions: `open_notebook` (convert/open notebook PDF), `wt` (create worktree + launch codex), `wtrm` (remove worktree + local branch).
- Enables Starship prompt and `zsh-autosuggestions`.

### Local overrides (`.zshrc.local`)

Use this for anything machine- or identity-specific:

- private hostnames
- user IDs
- local paths
- tokens/secrets

`~/.zshrc.local` is intentionally ignored by Git.

## Remote scripts (Jean-Zay workflow)

Files:

- `remote_scripts/mount_fct.sh`: shared mount/unmount functions
- `remote_scripts/mount_jz.sh`: mounts remote directories locally
- `remote_scripts/umount_jz.sh`: unmounts those local mount points
- `remote_scripts/rsync_jz.sh`: one-way local -> remote sync, then continuous watch/sync

Expected setup:

- SSH alias configured in `~/.ssh/config` (for example `<ssh-alias>`)
- Remote environment exposes `$WORK`

Typical usage:

```bash
jzmount
jzumount
jzrsync ~/path/to/project <remote-subpath-under-work>
```

Notes:

- `rsync_jz.sh` syncs tracked Git files only when source is a Git repo.
- Continuous mode uses `fswatch`; stop with `Ctrl-C`.

## Neovim setup

`nvim/init.lua` bootstraps `lazy.nvim` and configures:

- UI/theme and navigation defaults
- Telescope search mappings
- Treesitter highlighting
- LSP/completion via `mason.nvim`, `nvim-lspconfig`, `nvim-cmp`
- Git tools (`gitsigns`, `vim-fugitive`, `diffview`)
- Markdown rendering and filetype-specific behavior

`nvim/lazy-lock.json` pins plugin versions.

## Codex setup

`codex/config.toml` defines runtime behavior such as:

- model and reasoning level
- approval policy / sandbox mode
- enabled features (apps, multi-agent)

`codex/AGENTS.md` and `codex/skills/` contain reusable instructions and automation workflows used by Codex agents.

## Maintenance guidelines

- Keep tracked configs reusable and non-sensitive.
- Put machine- or account-specific data in `~/.zshrc.local`.
- If you add scripts, include usage/help text and update this README.
- Prefer small, focused commits grouped by topic (shell, nvim, codex, remote scripts).
- Re-check `PATH` changes to avoid stale directories.

## Troubleshooting

`jzmount`/`jzrsync` fails:

- Verify SSH alias exists: `ssh <ssh-alias>`
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

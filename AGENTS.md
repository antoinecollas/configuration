# Repository Guidelines

## Project Structure & Module Organization

This repository is a personal configuration monorepo (no `src/` app layout).

- `.zshrc`: primary Zsh configuration.
- `.zshrc.local`: machine-specific overrides (kept local, not for shared defaults).
- `remote_scripts/`: Bash helpers for mounting, unmounting, and syncing remote cluster directories.
- `nvim/`: Neovim config (`init.lua`) and plugin lockfile (`lazy-lock.json`).
- `codex/`: Codex settings, prompts, rules, and skills.
- `jz_configuration/`: alternate shell startup files for cluster environments.
- `generate_single_file.py`: utility to export tracked repo context into one Markdown file.

## Security & Configuration Tips

- Always update `README.md` after each modification in this repository.
- Never commit secrets, personal tokens, or private identifiers.
- Keep machine- or identity-specific values in `~/.zshrc.local`.
- Sanitize host aliases, user IDs, and internal paths in documentation and examples.

#!/usr/bin/env bash
set -euo pipefail
umask 022

# Run on LUMI from the cloned repository. Existing startup files are backed up.
config_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
command -v zsh >/dev/null 2>&1 || { echo 'Install Zsh before running setup.' >&2; exit 1; }
command -v git >/dev/null 2>&1 || { echo 'Install Git before running setup.' >&2; exit 1; }

if [[ ! -e "$HOME/.oh-my-zsh" ]]; then
  git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git "$HOME/.oh-my-zsh"
fi
if [[ ! -e "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions" ]]; then
  git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions.git \
    "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions"
fi
# LUMI's default group-writable permissions otherwise disable Zsh completion.
chmod -R go-w "$HOME/.oh-my-zsh"

backup_dir=$(mktemp -d "$HOME/.lumi-shell-backup.XXXXXXXX")
for name in .bash_profile .zshenv .zshrc; do
  [[ -L "$HOME/$name" && $(readlink "$HOME/$name") == "$config_dir/$name" ]] && continue
  if [[ -e "$HOME/$name" || -L "$HOME/$name" ]]; then
    mv -- "$HOME/$name" "$backup_dir/$name"
  fi
  ln -s -- "$config_dir/$name" "$HOME/$name"
done
printf 'Shell setup installed. Backups: %s\nReconnect with SSH to start Zsh.\n' "$backup_dir"

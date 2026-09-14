# Keep the LUMI login environment and existing user settings.
[[ -r "$HOME/.profile" ]] && source "$HOME/.profile"

# Leave SSH commands and batch shells in Bash.
if [[ $- == *i* ]]; then
  if command -v zsh >/dev/null 2>&1; then
    unset FPATH
    exec zsh
  else
    printf 'Zsh is unavailable; continuing with Bash.\n' >&2
  fi
fi

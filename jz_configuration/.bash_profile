# Load the full cluster environment in this shell for non-login SSH commands.
# Login shells already load /etc/profile automatically.
if ! shopt -q login_shell; then
  source /etc/profile
fi

# FPATH is used by some Fortran modules (e.g. Intel mkl), but it conflicts with zsh's fpath (function path).
unset FPATH

# User tools installed in HOME or WORK, plus zsh.
export PATH="$HOME/.local/bin:${WORK:+$WORK/.local/bin:}$HOME/.local/zsh-5.9/bin:$PATH"

# load zsh
# start zsh only for interactive shells
if [[ $- == *i* ]]; then
  if command -v zsh >/dev/null 2>&1; then
    exec zsh
  else
    printf 'Zsh is unavailable; continuing with Bash. Check your tool paths and storage access.\n' >&2
  fi
fi

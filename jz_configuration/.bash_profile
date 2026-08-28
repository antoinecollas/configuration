# FPATH is used by some Fortran modules (e.g. Intel mkl), but it conflicts with zsh's fpath (function path).
unset FPATH

# Resolve WORK for non-interactive SSH commands, where the cluster profile is not loaded.
if [[ -z "${WORK:-}" ]]; then
  WORK="$(bash -lc 'printf %s "$WORK"')"
  export WORK
fi

# User tools installed in HOME or WORK, plus zsh.
export PATH="$WORK/.local/bin:$HOME/.local/bin:$HOME/.local/zsh-5.9/bin:$PATH"

# load zsh
# start zsh only for interactive shells
if [[ $- == *i* ]]; then
  exec zsh
fi

# FPATH is used by some Fortran modules (e.g. Intel mkl), but it conflicts with zsh's fpath (function path).
unset FPATH

# load zsh
export PATH="$HOME/.local/zsh-5.9/bin:$PATH"
# start zsh only for interactive shells
if [[ $- == *i* ]]; then
  exec zsh
fi

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="robbyrussell"

plugins=(git)

source $ZSH/oh-my-zsh.sh


# User configuration

# openblas
export OPENBLAS_NUM_THREADS=1 
export MKL_NUM_THREADS=1
export NUMEXPR_NUM_THREADS=1
export OMP_NUM_THREADS=1

# ll command
alias ll='ls -alh'

# CDPATH for cd command
export CDPATH=~/Dropbox/postdoc/

# Set ulimit
ulimit -Sv 100000000	# 10GB

# squeue
alias squeue_me='squeue -u acollas'
alias squeue_all='squeue -u all'
alias slurm_top="squeue -h -o '%.8u %.2C %.2t' -t R | awk '{arr[\$1]+=\$2} END {for (i in arr) {print i \": \" arr[i] \" cores\"}}' | sort -k2,2nr"


# specific to linux

# cuda
export PATH=/usr/local/cuda/bin${PATH:+:${PATH}}$ 
export LD_LIBRARY_PATH=/usr/local/cuda/lib64${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}

# julia
export PATH=$PATH:~/julia/bin/

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('${HOME}/miniconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "${HOME}/miniconda3/etc/profile.d/conda.sh" ]; then
        . "${HOME}/miniconda3/etc/profile.d/conda.sh"
    else
        export PATH="${HOME}/miniconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<

# codexwt <feature_name>
# - Ensures you're inside a git repo
# - Updates local main from upstream (checkout main + pull upstream main)
# - Creates (or reuses) a branch named <feature_name>
# - Creates a sibling worktree directory named: <repo>__<feature_name>
# - cd's into that worktree and launches `codex`
codexwt() {
  # Enforce exact usage: one argument only
  [ "$#" -eq 1 ] || { echo "Usage: codexwt <feature_name>" >&2; return 2; }

  local feature="$1"
  local top repo parent dir branch

  # Find the repo root; fail if not in a git repo
  top="$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "codexwt: not inside a git repo" >&2; return 2; }

  # Build names/paths:
  # - repo: repository folder name (used to name the worktree dir)
  # - parent: parent directory of the repo root (so worktree is a sibling)
  # - branch: branch name equals feature name
  # - dir: sibling worktree directory path (e.g., ../myrepo__my-feature)
  repo="$(basename "$top")"
  parent="$(dirname "$top")"
  branch="$feature"
  dir="$parent/${repo}__${feature}"

  # Update main from upstream before branching/worktree creation
  git -C "$top" checkout main || return $?
  git -C "$top" pull upstream main || return $?

  # Avoid clobbering an existing directory
  [ ! -e "$dir" ] || { echo "codexwt: path already exists: $dir" >&2; return 2; }

  # If the branch already exists locally, add a worktree using it.
  # Otherwise, create the branch and the worktree in one go.
  if git -C "$top" show-ref --verify --quiet "refs/heads/$branch"; then
    git -C "$top" worktree add "$dir" "$branch" || return $?
  else
    git -C "$top" worktree add -b "$branch" "$dir" || return $?
  fi

  # Enter the worktree and launch Codex
  cd "$dir" || return 1
  command codex
}

# codexrm <feature_name>
# - Ensures you're inside a git repo
# - Removes the sibling worktree directory: <repo>__<feature_name>
# - Deletes the local branch named <feature_name>
# Notes:
# - Uses --force for worktree removal (handy if Codex left files around)
# - Uses -D for branch deletion (force delete); adjust to -d if you prefer safety
codexrm() {
  # Enforce exact usage: one argument only
  [ "$#" -eq 1 ] || { echo "Usage: codexrm <feature_name>" >&2; return 2; }

  local feature="$1"
  local top repo parent dir branch

  # Find the repo root; fail if not in a git repo
  top="$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "codexrm: not inside a git repo" >&2; return 2; }

  # Reconstruct the same branch/dir names used by codexwt
  repo="$(basename "$top")"
  parent="$(dirname "$top")"
  branch="$feature"
  dir="$parent/${repo}__${feature}"

  # Remove the worktree directory if it exists
  if [ -e "$dir" ]; then
    git -C "$top" worktree remove --force "$dir" || return $?
  else
    echo "codexrm: no worktree path: $dir" >&2
  fi

  # Delete the local branch if it exists
  if git -C "$top" show-ref --verify --quiet "refs/heads/$branch"; then
    git -C "$top" branch -D "$branch" || return $?
  else
    echo "codexrm: no branch: $branch" >&2
  fi
}

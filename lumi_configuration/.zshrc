# Use terminal capabilities supported by LUMI for prompt redraw and Backspace.
export TERM=xterm-256color

# Initialize LUMI's module command for Zsh using the inherited site environment.
if (( ! $+functions[module] )) && [[ -r "${MODULESHOME:-}/init/zsh" ]]; then
  source "$MODULESHOME/init/zsh"
fi

typeset -U path
path=("$HOME/.local/bin" "$HOME/configuration/scripts" $path)
export PATH

export OPENBLAS_NUM_THREADS=1
export MKL_NUM_THREADS=1
export NUMEXPR_NUM_THREADS=1
export OMP_NUM_THREADS=1

HISTFILE="$HOME/.zsh_history"
HISTSIZE=10000
SAVEHIST=10000
setopt APPEND_HISTORY HIST_IGNORE_DUPS HIST_IGNORE_SPACE
bindkey -e

# Setup installs the same prompt/plugins as Jean Zay; keep a standalone fallback.
export ZSH="$HOME/.oh-my-zsh"
if [[ -r "$ZSH/oh-my-zsh.sh" ]]; then
  ZSH_THEME="robbyrussell"
  zstyle ':omz:update' mode disabled
  plugins=(git)
  if [[ -r "${ZSH_CUSTOM:-$ZSH/custom}/plugins/zsh-autosuggestions/zsh-autosuggestions.plugin.zsh" ]]; then
    plugins+=(zsh-autosuggestions)
  fi
  source "$ZSH/oh-my-zsh.sh"
else
  autoload -Uz compinit
  compinit
  PROMPT='%n@%m %~ %# '
fi

# Keep commands available across SSH sessions, including sessions still open.
setopt SHARE_HISTORY

alias ll='ls -alh'

# Project paths, account IDs, and other machine-specific settings stay local.
if [[ -r "$HOME/.zshrc.local" ]]; then
  source "$HOME/.zshrc.local"
fi

# HOME is supplied by LUMI. Select the project in ~/.zshrc.local.
export HOME
if [[ -n "${LUMI_ACCOUNT:-}" ]]; then
  export PROJECT="${PROJECT:-/project/$LUMI_ACCOUNT}"
  export SCRATCH="${SCRATCH:-/scratch/$LUMI_ACCOUNT}"
  export FLASH="${FLASH:-/flash/$LUMI_ACCOUNT}"
fi

# Select ROCm for uv pip installations.
export UV_TORCH_BACKEND=rocm6.4

# Match Jean Zay's centralized uv environments, using personal flash storage.
if [[ -n "${FLASH:-}" ]]; then
  export UV_CACHE_DIR="${UV_CACHE_DIR:-$FLASH/$USER/uv-cache}"
  export UV_PYTHON_INSTALL_DIR="${UV_PYTHON_INSTALL_DIR:-$FLASH/$USER/uv-python}"
  export UV_PREVIEW_FEATURES="centralized-project-envs"
fi

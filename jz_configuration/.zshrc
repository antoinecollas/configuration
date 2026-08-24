# Load oh-my-zsh
ZSH_THEME="robbyrussell"
zstyle ':omz:update' mode disabled

plugins=(git zsh-autosuggestions)

export ZSH="$HOME/.oh-my-zsh"
source $ZSH/oh-my-zsh.sh

# Initialize Jean Zay environment modules
if ! type module >/dev/null 2>&1; then
  _module_home="${MODULESHOME:-$(bash -lc 'printf %s "$MODULESHOME"')}"
  [[ -r "$_module_home/init/zsh" ]] && source "$_module_home/init/zsh"
  unset _module_home
fi

# User configuration

# openblas
export OPENBLAS_NUM_THREADS=1 
export MKL_NUM_THREADS=1
export NUMEXPR_NUM_THREADS=1
export OMP_NUM_THREADS=1

export TORCHINDUCTOR_CACHE_DIR=$WORK/torchinductor_cache

# ll command
alias ll='ls -alh'

# Modules
# module purge
# module load arch/h100
# module load pytorch-gpu/py3/2.8.0

# Add $HOME/.local/bin to PATH
export PATH="$HOME/.local/bin:$PATH"

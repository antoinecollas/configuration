# Load oh-my-zsh
ZSH_THEME="robbyrussell"

plugins=(git)

export ZSH="$HOME/.oh-my-zsh"
source $ZSH/oh-my-zsh.sh

# make module work

# Source /usr/share/Modules/init/zsh if it exists
if [[ -s "/usr/share/Modules/init/zsh" ]]; then
  source /usr/share/Modules/init/zsh
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

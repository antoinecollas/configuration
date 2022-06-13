# Path to your oh-my-zsh installation.
export ZSH="/home/antoinecollas/.oh-my-zsh"

ZSH_THEME="robbyrussell"

plugins=(git)

source $ZSH/oh-my-zsh.sh


# User configuration

# openblas
export OPENBLAS_NUM_THREADS=1 

# ll command
alias ll='ls -al'

# CDPATH for cd command
export CDPATH=~/Dropbox/PhD/:~/Dropbox/PhD/Riemannian_clustering


# specific to linux

# cuda
export PATH=/usr/local/cuda/bin${PATH:+:${PATH}}$ 
export LD_LIBRARY_PATH=/usr/local/cuda/lib64${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}

# julia
export PATH=$PATH:~/julia/bin/

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/home/antoinecollas/anaconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/home/antoinecollas/anaconda3/etc/profile.d/conda.sh" ]; then
        . "/home/antoinecollas/anaconda3/etc/profile.d/conda.sh"
    else
        export PATH="/home/antoinecollas/anaconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<

HOME="/home/mind/acollas"

# Path to your oh-my-zsh installation.
export ZSH="${HOME}/.oh-my-zsh"

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
alias ll='ls -al'

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

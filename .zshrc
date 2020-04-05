# Path to your oh-my-zsh installation.
export ZSH="/home/collasa/.oh-my-zsh"

ZSH_THEME="robbyrussell"

plugins=(git)

source $ZSH/oh-my-zsh.sh

# User configuration

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/home/collasa/anaconda3/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/home/collasa/anaconda3/etc/profile.d/conda.sh" ]; then
        . "/home/collasa/anaconda3/etc/profile.d/conda.sh"
    else
        export PATH="/home/collasa/anaconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<

export PATH=$PATH:~/julia/bin/

export OPENBLAS_NUM_THREADS=1 

export PATH=/usr/local/cuda/bin${PATH:+:${PATH}}$ 
export LD_LIBRARY_PATH=/usr/local/cuda/lib64${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}

alias ll='ls -al'

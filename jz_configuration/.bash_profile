# If interactive on a front-end and not already zsh, switch early.
case $- in *i*)
	if [[ $(hostname -s) =~ ^jean-zay[0-9]+$ ]]; then
		export PATH="$HOME/.local/zsh-5.9/bin:$PATH"
		exec zsh
	fi
	;; esac

# Otherwise, normal bash init
[ -f ~/.bashrc ] && . ~/.bashrc

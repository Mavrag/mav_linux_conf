# .bashrc

# User specific aliases and functions

alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
alias ll='ls -lah'
alias gate'ssh root@mavrag.com'

# Source global definitions
if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi

[ -f ~/.fzf.bash ] && source ~/.fzf.bash

if [ -z "$SSH_AUTH_SOCK" ] ; then
   eval `ssh-agent -s`
   ssh-add
fi

#!/bin/bash
# indicate our inclusion to all who follow
__gosh_terminal="terminal.bash"
__gosh_terminal_includes=$( basename "${__gosh_terminal}" ".bash" )".d"

# source all files in the includes directory
if [[ -d "${__gosh_terminal_includes}" ]]; then
  for inc in "${__gosh_terminal_includes}"/*; do
    . "${inc}"
  done
fi

export HISTCONTROL=$HISTCONTROL${HISTCONTROL+,}ignoredups
export HISTSIZE=4096
export HISTFILESIZE=8192

shopt -s histappend
shopt -s checkwinsize
shopt -s globstar

export prompt_color=1
export umask_default=0022

[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

umask ${umask_default}

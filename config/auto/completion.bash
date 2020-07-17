#!/bin/bash

# source the completion scripts pre-installed on the system
global_bash_completion="/usr/share/bash-completion/bash_completion"
system_bash_completion="/etc/bash_completion"
if ! shopt -oq posix; then
	if [ -f "${global_bash_completion}" ]; then
		. "${global_bash_completion}"
	elif [ -f "${system_bash_completion}" ]; then
		. "${system_bash_completion}"
	fi
fi

# basic Makefile completion
complete -W "\`[[ -f Makefile ]] && "                          \
	"command grep -oE '^[a-zA-Z0-9_.-]+:([^=]|$)' Makefile | " \
	"sed 's/[^a-zA-Z0-9_.-]*$//'\`" make

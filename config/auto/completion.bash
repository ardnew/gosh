#!/bin/bash
# indicate our inclusion to all who follow
__gosh_completion="completion.bash"
__gosh_completion_includes=$( basename "${__gosh_completion}" ".bash" )".d"

# source all files in the includes directory
if [[ -d "${__gosh_completion_includes}" ]]; then
	for inc in "${__gosh_completion_includes}"/*; do
		. "${inc}"
	done
fi

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

# Go completion
go_completion="${GOPATH}/bin/gocomplete"
[[ -f "${go_completion}" ]] && complete -C "${go_completion}" go

# basic Makefile completion
complete -W "\`[[ -f Makefile ]] && "                          \
	"command grep -oE '^[a-zA-Z0-9_.-]+:([^=]|$)' Makefile | " \
	"sed 's/[^a-zA-Z0-9_.-]*$//'\`" make

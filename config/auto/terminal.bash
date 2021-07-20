#!/bin/bash

# search for a vi executable (in decreasing precedence, from left-to-right)
if e=$( type -P nvim ) || e=$( type -P vim ) || e=$( type -P vi ); then
	EDITOR=$( readlink -f "${e}" )
fi

[[ -x ${EDITOR} ]] &&
	export EDITOR VISUAL=${EDITOR}

export EMAIL="andrew@ardnew.com"

export PAGER='less -RF'
export MANPAGER="${PAGER} -X"

# use nvimpager as man pager, if it is installed
mp=$( type -P nvimpager ) &&
	export MANPAGER=${mp}

test is-host-darwin || export LANG='en_US.utf8'

export HISTCONTROL=$HISTCONTROL${HISTCONTROL+,}ignoredups
export HISTSIZE=4096
export HISTFILESIZE=8192

shopt -s histappend
shopt -s checkwinsize

test is-host-darwin || shopt -s globstar

export prompt_color=1
export umask_default=0022

export BASH_SILENCE_DEPRECATION_WARNING=1

lp=$( type -P lesspipe ) &&
	eval "$( SHELL=/bin/sh "${lp}" )"

umask ${umask_default}

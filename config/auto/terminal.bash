#!/bin/bash

if e=$( type -P nvim ) || e=$( type -P vim ) || e=$( type -P vi ); then
	EDITOR=$( readlink -f "${e}" )
fi

if [[ -x ${EDITOR} ]]; then
	export EDITOR VISUAL=${EDITOR}
fi

export PAGER='less -RF'

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

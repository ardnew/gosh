#!/bin/bash

# ==============================================================================
#
#  file: 010-paths.env.bash
#
#  date: 19 June 2020
#
#  auth: andrew@ardnew.com
#
#  desc: path definitions for various shell settings and applications
#
# ==============================================================================

# ---------------------------------------------------------- path definitions --

case "${host_kind}" in
	$host_linux)
		path_go="${HOME}/Code/go"
		path_nvim="${HOME}/.config/nvim"
		;;
	$host_darwin)
		;;
	$host_cygwin)
		;;
	$host_mswsl)
		;;
	*)
		;;
esac

export GOPATH="${path_go}"
export VIM="${path_vim}"

export PATH="${GOPATH}/bin:/usr/local/bin:${PATH}"
export LD_LIBRARY_PATH="/usr/local/lib:${LD_LIBRARY_PATH}"

# ---------------------------------------------------- terminal configuration --

export HISTCONTROL=$HISTCONTROL${HISTCONTROL+,}ignoredups
export HISTSIZE=4096
export HISTFILESIZE=8192

shopt -s histappend
shopt -s checkwinsize
shopt -s globstar

export prompt_color=1
export umask_default=0022

[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"


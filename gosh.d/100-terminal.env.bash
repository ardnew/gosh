#!/bin/bash

# ==============================================================================
#
#  file: environment.bash
#
#  date: 19 June 2020
#
#  auth: andrew@ardnew.com
#
#  desc: various environment variables used by shell functions and aliases
#
# ==============================================================================

# ---------------------------------------------------------- useful constants --

export datetime_format="%Y-%h-%d %H:%M:%S"
export datetime_file_format="%Y-%m-%d__%H-%M-%S"
export datetime_unix_format="%s"

export bytes_kb=$(( 10 ** 3 ))
export bytes_kib=$(( 2 ** 10 ))
export bytes_mb=$(( $bytes_kb ** 2 ))
export bytes_mib=$(( $bytes_kib ** 2 ))
export bytes_gb=$(( $bytes_kb ** 3 ))
export bytes_gib=$(( $bytes_kib ** 3 ))

# ------------------------------------------------------------- host identity --

export host_linux=1
export host_darwin=2
export host_cygwin=3
export host_mswsl=4

[[ "${OSTYPE}" = *linux* ]] &&
	host_kind=${host_linux}
[[ "${OSTYPE}" = *darwin* ]] &&
	host_kind=${host_darwin}
[[ "${OSTYPE}" = *cygwin* ]] &&
	host_kind=${host_cygwin}
[[ "$( uname -a | tr '[:upper:]' '[:lower:]' )" =~ microsoft ]] &&
	host_kind=${host_mswsl}

export host_kind

# ---------------------------------------------------------- path definitions --

case "${host_kind}" in
	$host_linux)
		path_go="${HOME}/dev/go"
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


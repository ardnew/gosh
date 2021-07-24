#!/bin/bash

case "${host_kind}" in
	$host_linux)
		;;
	$host_darwin)
		path_gnubin="/opt/local/libexec/gnubin"
		;;
	$host_cygwin)
		;;
	$host_mswsl)
		;;
	*)
		;;
esac

auto_aliases="$( goshconfig -d )/auto/aliases.bash"

[[ -n ${path_gnubin} ]] && 
	PATH=$( prepath PATH "${path_gnubin}" )
PATH=$( prepath PATH '/usr/local/bin' "${HOME}/.local/bin" )
LD_LIBRARY_PATH=$( prepath LD_LIBRARY_PATH "${HOME}/.local/lib" "/usr/local/lib" )
MANPATH=$( prepath MANPATH '/usr/local/share/man' '/usr/share/man' )

INPUTRC="$( goshconfig -d )/auto/inputrc" 

if [[ -f "${HOME}/.inputrc" ]] && [[ ! -L "${HOME}/.inputrc" ]] ||
		[[ "${INPUTRC}" != $( readlink -f "${HOME}/.inputrc" ) ]]; then
	rm -f "${HOME}/.inputrc"
	ln -sf "${INPUTRC}" "${HOME}/.inputrc"
fi

export PATH LD_LIBRARY_PATH INPUTRC MANPATH

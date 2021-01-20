#!/bin/bash

case "${host_kind}" in
	$host_linux)
		path_hugo="/usr/local/src/hugo"
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

if [[ -d "${path_hugo}" ]]; then
	man_hugo="${path_hugo}/share/man"
	[[ -d "${man_hugo}" ]] && MANPATH="${man_hugo}:${MANPATH}"
fi

export MANPATH

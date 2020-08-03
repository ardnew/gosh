#!/bin/bash

case "${host_kind}" in
	$host_linux)
		path_hub="/usr/lib/hub"
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

if [[ -d "${path_hub}" ]]; then
	PATH="${path_hub}/bin:${PATH}"
	man_hub="${path_hub}/share/man"
	[[ -d "${man_hub}" ]] && MANPATH="${man_hub}:${MANPATH}"
fi

export PATH MANPATH

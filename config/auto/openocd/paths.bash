#!/bin/bash

case "${host_kind}" in
	$host_linux)
		path_openocd="/usr/lib/openocd"
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

if [[ -d "${path_openocd}" ]]; then
	PATH="${path_openocd}/bin:${PATH}"
	man_openocd="${path_openocd}/share/man"
	[[ -d "${man_openocd}" ]] && MANPATH="${man_openocd}:${MANPATH}"
fi

export PATH MANPATH

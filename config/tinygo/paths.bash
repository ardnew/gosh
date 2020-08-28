#!/bin/bash

case "${host_kind}" in
	$host_linux)
		root_tinygo="/usr/local/src/tinygo/dev"
		path_tinygo="${HOME}/Code/tinygo"
		bootstrap_go="/usr/local/lib/go1.14.4"
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

[[ -d "${bootstrap_go}" ]] && GOROOT="${bootstrap_go}"

if [[ -d "${path_tinygo}" ]]; then
	TINYGOROOT="${root_tinygo}"
	TINYGOPATH="${path_tinygo}"
	PATH="${TINYGOPATH}/bin:${TINYGOROOT}/build:${PATH}"
fi

export TINYGOROOT TINYGOPATH PATH


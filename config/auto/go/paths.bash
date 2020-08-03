#!/bin/bash

case "${host_kind}" in
	$host_linux)
		path_go="${HOME}/Code/go"
		path_goshfun="${HOME}/.local/bin/gosh"
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

if [[ -d "${path_go}" ]]; then
	GOPATH="${path_go}"
	PATH="${GOPATH}/bin:${PATH}"
fi

[[ -d "${path_goshfun}" ]] && PATH="${path_goshfun}:${PATH}"

export GOPATH PATH

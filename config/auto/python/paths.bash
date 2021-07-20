#!/bin/bash

case "${host_kind}" in
	${host_linux})
		;;
	${host_darwin})
		path_python="${HOME}/Library/Python/3.9"
		;;
	${host_cygwin})
		;;
	${host_mswsl})
		;;
	*)
		;;
esac

[[ -d "${path_python}" ]] &&
	PATH="${path_python}/bin:${PATH}"

export PATH


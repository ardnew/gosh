#!/bin/bash

case "${host_kind}" in
	${host_linux})
		path_poetry="${HOME}/.poetry"
		;;
	${host_darwin})
		;;
	${host_cygwin})
		;;
	${host_mswsl})
		;;
	*)
		;;
esac

[[ -d "${path_poetry}/bin" ]] &&
	PATH="${path_poetry}/bin:${PATH}"

export PATH


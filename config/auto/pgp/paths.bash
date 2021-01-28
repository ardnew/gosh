#!/bin/bash

case "${host_kind}" in
	${host_linux})
		path_pgp="${HOME}/.gnupg"
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

[[ -d "${path_pgp}" ]] && PGPPATH="${path_pgp}"

export PGPPATH


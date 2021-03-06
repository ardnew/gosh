#!/bin/bash

case "${host_kind}" in
	${host_linux})
		path_pgp="${HOME}/.gnupg"
		sock_ssh=$( gpgconf --list-dirs agent-ssh-socket )
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

if [[ -d "${path_pgp}" ]]; then
	PGPPATH="${path_pgp}"
	GNUPGHOME="${path_pgp}"
fi

if [[ -S "${sock_ssh}" ]]; then
	# don't export unless our socket really exists
	export SSH_AUTH_SOCK="${sock_ssh}"
fi

export PGPPATH GNUPGHOME


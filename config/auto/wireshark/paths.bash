#!/bin/bash

case "${host_kind}" in
	${host_linux})
		wireshark_path="${HOME}/.local/bin/wireshark"
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

[[ -d "${wireshark_path}" ]] &&
	PATH="${wireshark_path}:${PATH}"

export PATH

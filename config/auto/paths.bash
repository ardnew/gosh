#!/bin/bash

case "${host_kind}" in
	$host_linux)
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

PATH="${HOME}/.local/bin:/usr/local/bin:${PATH}"
LD_LIBRARY_PATH="${HOME}/.local/lib:/usr/local/lib:${LD_LIBRARY_PATH}"

export PATH LD_LIBRARY_PATH

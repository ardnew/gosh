#!/bin/bash

case "${host_kind}" in
	$host_linux)
		path_nvim="${HOME}/.config/nvim"
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

VIM="${path_vim}"
PATH="${HOME}/.local/bin:/usr/local/bin:${PATH}"
LD_LIBRARY_PATH="${HOME}/.local/lib:/usr/local/lib:${LD_LIBRARY_PATH}"

export VIM PATH LD_LIBRARY_PATH

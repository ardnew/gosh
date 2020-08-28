#!/bin/bash

case "${host_kind}" in
	$host_linux)
		path_gitconfig="${HOME}/.config/git/config"
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

[[ -d "${path_gitconfig}" ]] && 
	export GIT_CONFIG="${path_gitconfig}"


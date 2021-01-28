#!/bin/bash

case "${host_kind}" in
	$host_linux)
		man_restic="/usr/local/share/restic/man"
		config_restic="/mnt/backup/restic"
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

if [[ -d "${config_restic}" ]]; then
	path_name="repo.path"
	[[ -f "${config_restic}/${path_name}" ]] && 
		RESTIC_REPOSITORY_FILE="${config_restic}/${path_name}"
	pass_name="repo.pass"
	[[ -f "${config_restic}/${pass_name}" ]] && 
		RESTIC_PASSWORD_FILE="${config_restic}/${pass_name}"
	include_name="include.path"
	[[ -f "${config_restic}/${include_name}" ]] && 
		RESTIC_INCLUDES_FILE="${config_restic}/${include_name}"
	exclude_name="exclude.path"
	[[ -f "${config_restic}/${exclude_name}" ]] && 
		RESTIC_EXCLUDES_FILE="${config_restic}/${exclude_name}"
fi

[[ -d "${man_restic}" ]] && MANPATH="${man_restic}:${MANPATH}"

export MANPATH RESTIC_REPOSITORY_FILE RESTIC_PASSWORD_FILE RESTIC_INCLUDES_FILE RESTIC_EXCLUDES_FILE

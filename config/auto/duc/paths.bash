#!/bin/bash

case "${host_kind}" in
	$host_linux)
		duc_root_path="/"
		duc_backup_path="/mnt/backup"
		duc_media_path="/mnt/media"
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

duc_volume=(
	"root"   "${duc_root_path}"
	"backup" "${duc_backup_path}"
	"media"  "${duc_media_path}"
)
duc_database_name=".index.duc"


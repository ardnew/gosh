#!/bin/bash

case "${host_kind}" in
	$host_linux)
		bat_config_path="/usr/local/share/bat/config"
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

[[ -n ${bat_config_path} ]] && [[ -f "${bat_config_path}" ]] &&
	BAT_CONFIG_PATH="${bat_config_path}"

export BAT_CONFIG_PATH

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


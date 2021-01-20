#!/bin/bash

case "${host_kind}" in
	$host_linux)
		lib_perl5="/usr/share/perl5"
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

if [[ -d "${lib_perl5}" ]]; then
	if [[ -n ${PERL5LIB} ]]; then
		# ensure the path does not already exist
		if [[ ! "${PERL5LIB}" =~ (^|:+)\s*${lib_perl5}\s*($|:+) ]]; then
			PERL5LIB="${lib_perl5}:${PERL5LIB}"
		fi
	else
		PERL5LIB="${lib_perl5}"
	fi
fi

export PERL5LIB


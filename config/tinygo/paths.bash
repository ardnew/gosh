#!/bin/bash

split-go-version() {
	if [[ $# -gt 0 ]]; then
		perl -pe 's/^\s*go//;s/\s+$//;s/\./\t/g' <<< "${1}"
	fi
}

case "${host_kind}" in
	$host_linux)
		root_tinygo="/usr/local/src/tinygo"
		path_tinygo="${GOPATH}"
		# uncomment once TinyGo supports mainline Go
		#dev_go="/usr/local/src/go/dev"
		bootstrap_go="/usr/local/lib/go1.15.4"
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

if [[ -d "${dev_go}" ]]; then
	if [[ -f "${dev_go}/VERSION" ]]; then
		dev_version=( $( split-go-version $( cat "${dev_go}/VERSION" ) ) )
		if [[ ${#dev_version[@]} -gt 0 ]] && [[ ${dev_version[0]} -gt 0 ]]; then
			bootstrap_go=${dev_go}
		fi
	fi
fi

[[ -d "${bootstrap_go}" ]] && GOROOT="${bootstrap_go}"

if [[ -d "${path_tinygo}" ]]; then
	TINYGOROOT="${root_tinygo}"
	TINYGOPATH="${path_tinygo}"
	GOPATH="${TINYGOPATH}:${GOPATH}"
	GOBOOT="${bootstrap_go}"
	PATH="${GOBOOT}/bin:${TINYGOPATH}/bin:${TINYGOROOT}/build:${PATH}"
fi

export TINYGOROOT TINYGOPATH GOPATH GOBOOT PATH


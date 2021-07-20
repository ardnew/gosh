#!/bin/bash

split-go-version() {
	if [[ $# -gt 0 ]]; then
		perl -pe 's/^\s*go//;s/\s+$//;s/\./\t/g' <<< "${1}"
	fi
}

prepend-to-gopath() {
	# process each argument independently
	for arg in "${@}"; do
		# echo each element in the ":"-delimited list arg that is not also in GOPATH
		filepath.SplitList "${arg}" | 
			xargs -L1 -I{} bash -c '
					rex=$( echo -nE "{}" | sed -E "s/ /[[:space:]]/g" )
					[[ "'${GOPATH}'" =~ (^|:+)\s*${rex}\s*($|:+) ]] || echo {}
				'
	done
}

case "${host_kind}" in
	$host_linux)
		root_tinygo="/usr/local/src/tinygo"
		path_tinygo="${GOPATH}"
		# uncomment once TinyGo supports mainline Go
		dev_go="/usr/local/go/dev"
		#bootstrap_go="/usr/local/go/opt/go1.15.8"
		;;
	$host_darwin)
		root_tinygo="/usr/local/tinygo"
		path_tinygo="${GOPATH}"
		# uncomment once TinyGo supports mainline Go
		dev_go="/usr/local/go/opt/1.15.2"
		#bootstrap_go="/usr/local/go/ver/go1.15.8"
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
	# don't add TINYGOPATH to PATH if it already exists
	prepend-to-gopath "${TINYGOPATH}" |
		while read -re path; do GOPATH="${path}:${GOPATH}";	done
	GOBOOT="${bootstrap_go}"
	PATH="${GOBOOT}/bin:${TINYGOPATH}/bin:${TINYGOROOT}/build:${PATH}"
fi

export TINYGOROOT TINYGOPATH GOPATH GOBOOT PATH


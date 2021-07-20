#!/bin/bash

pio_pip='pip3'
pio_python='python3'

pio_url='https://github.com/platformio/platformio-core/archive/develop.zip'

pio-install() {

	local -a args
	local pip

	while getopts ":p:" o; do
		case "${o}" in
			p) pip=${OPTARG} ;;
			*) erro -f 'usage:\n\t{0} [-p pip-path]\n' 'pip-install' ; return ;;
		esac
	done

	#trap "set +ex ERR RETURN" ERR RETURN
	#set -ex

	[[ -z ${pip} ]] && 
		pip=$( type -P "${pio_pip}" )

	${pip} install --user -U "${pio_url}"
}

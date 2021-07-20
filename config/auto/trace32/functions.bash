#!/bin/bash

license_data_t32=' ;;2;; G003B00383139511636323431 cpu.arm.portentah7             2022-02-12 temporary    YX5FXN.ERBNTM.CZSS7B.6NNR37.ZVQ88B.S29X6T.10QMMP.AXYVH0 andrew@ardnew.com ;;eol;; '

trace32-update-port() {
	arduino_bin='arduino-cli'
	fqbn='arduino:mbed:envie_m7'
	if cli=$( type -P "${arduino_bin}" ); then
		if board=( $( "${cli}" board list | command grep -P '\b'"${fqbn}"'\b' ) ); then
			port=${board[0]}
			if [[ -n ${settings_t32} ]] && [[ -f "${settings_t32}" ]]; then
				cp -v "${settings_t32}" "${settings_t32}.bak"
				perl -e '
use strict;
use warnings;

my ($port) = $ARGV[0];
my ($blkfnd, $asnfnd) = (0, 0);

while (<STDIN>) {
	if (not $blkfnd) {
		if (/ELSE IF OS\.NAME\(\)=="Linux"/) {
			$blkfnd = 1;
		}
	}	elsif (not $asnfnd) {
		if (/&GDBPORT="[^"]*"/) {
			$asnfnd = 1;
			s/(&GDBPORT=")[^"]*/${1}${port}/;
		}
	}
	print;
}
				' "${port}" < "${settings_t32}.bak" > "${settings_t32}"
				diff "${settings_t32}.bak" "${settings_t32}"
			else
				echo "error: trace32 settings file not found: ${settings_t32}"
			fi
		else
			echo "error: board not found: ${fqbn}"
			return 2
		fi
	else
		echo "error: executable not found: ${arduino_bin}"
		return 1
	fi
}

trace32() {
	trace32_bin='t32marm'
	if trace32_bin="$( type -P "${trace32_bin}" )"; then
		if [[ -n ${license_t32} ]]; then
			# install the license file
			printf "%s" "${license_data_t32}" > "${license_t32}"
			if [[ -n ${root_t32} ]]; then
				trace32-update-port || return $?
				pushd "${root_t32}" &> /dev/null
				"${trace32_bin}"
				popd &> /dev/null
			else
				echo "error: trace32 root path undefined"
				return 3
			fi
		else
			echo "error: trace32 license file path undefined"
			return 2
		fi
	else
		echo "error: trace32 executable not found: ${trace32_bin}"
		return 1
	fi
}

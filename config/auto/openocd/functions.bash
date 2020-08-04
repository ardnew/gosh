#!/bin/bash

OPENOCD_PREFIX_DEFAULT="/usr/local/lib/openocd"
OPENOCD_TELNET_PORT_DEFAULT=4444

openocd-telnet-usage() {

	[[ -z $OPENOCD_PREFIX ]] && OPENOCD_PREFIX=${OPENOCD_PREFIX_DEFAULT}
	[[ -z $OPENOCD_TELNET_PORT ]] && OPENOCD_TELNET_PORT=${OPENOCD_TELNET_PORT_DEFAULT}

	cat <<__USAGE__
USAGE

	openocd-telnet [-h]
	openocd-telnet -i INTERFACE -t TARGET [-c CMD]
	
FLAGS

	--help, -h           - this cruft
	--interface, -i      - interface used for target communication (see notes)
	--target, -t         - target device identifier (see notes)
	--command, -c        - use given CMD instead of 'init' to start OpenOCD

ENVIRONMENT VARIABLES

	OPENOCD_PREFIX       - the installation prefix where OpenOCD was installed.
	                       (default: ${OPENOCD_PREFIX_DEFAULT})
	OPENOCD_TELNET_PORT  - the TCP port opened by OpenOCD to which telnet will
	                       attempt a connection (default: ${OPENOCD_TELNET_PORT_DEFAULT})

NOTES

	The arguments given to both --interface and --target may be either a full
	path to or the name of (.cfg extension optional) an OpenOCD script file.

	If only NAME is given, the path to the selected script file is as follows:

		--interface NAME:	
			\${OPENOCD_PREFIX}/share/openocd/scripts/interface/\${NAME}.cfg

		--target NAME:
			\${OPENOCD_PREFIX}/share/openocd/scripts/target/\${NAME}.cfg

	Otherwise, the given full path to the respective scripts is used verbatim.

__USAGE__
}

openocd-telnet() {

	[[ -z $OPENOCD_PREFIX ]] && OPENOCD_PREFIX=${OPENOCD_PREFIX_DEFAULT}
	[[ -z $OPENOCD_TELNET_PORT ]] && OPENOCD_TELNET_PORT=${OPENOCD_TELNET_PORT_DEFAULT}

	local args interface target initcmd

	if [[ $# -eq 0 ]]; then
		openocd-telnet-usage
		return -1
	fi

	initcmd='init'

	while test $# -gt 0
	do
		case "${1}" in
		(--help|-h)			openocd-telnet-usage ; return -1 ;;
		(--interface|-i)	shift ; interface=${1} ;;
		(--target|-t)		shift ; target=${1} ;;
		(--command|-c)		shift ; initcmd=${1} ;;
		(*)					args=( "${args[@]}" "$1" ) ;;
		esac
		shift
	done

	if [[ ! -f "${interface}" ]]; then
		interface=$( basename "${interface}" .cfg )
		interface="${OPENOCD_PREFIX}/share/openocd/scripts/interface/${interface}.cfg"
	fi
	if [[ ! -f "${interface}" ]]; then
		echo "error: OpenOCD interface script not found: ${interface}"
		return 1
	fi

	if [[ ! -f "${target}" ]]; then
		target=$( basename "${target}" .cfg )
		target="${OPENOCD_PREFIX}/share/openocd/scripts/target/${target}.cfg"
	fi
	if [[ ! -f "${target}" ]]; then
		echo "error: OpenOCD target script not found: ${target}"
		return 2
	fi

	interface_name=$( basename "${interface}" '.cfg' )
	target_name=$( basename "${target}" '.cfg' )

	session="openocd-${interface_name}-${target_name}"

	openocd_cmd="openocd -f \"${interface}\" -f \"${target}\""
	[[ -n ${initcmd} ]] && openocd_cmd="${openocd_cmd} -c \"${initcmd}\""

	telnet_cmd="sleep 1 && telnet localhost ${OPENOCD_TELNET_PORT}"

	tmux -u -2 \
		new-session -d -s "${session}" "${openocd_cmd}" \; \
		split-window "${telnet_cmd}" \; \
		attach
}

#!/bin/bash

tinygo-targets() {
	if [[ ! -d "${TINYGOROOT}" ]]; then
		echo "error: invalid or unset TINYGOROOT"
		return 1
	fi
	targets=( $( find "${TINYGOROOT}/targets" -type f -name '*.json' -print0 | xargs -0 basename -a -s '.json' ) )
	if [[ ${#} -gt 0 ]]; then
		printf -- "%s\n" "${targets[@]}" | command grep "${@}"
	else
		printf -- "%s\n" "${targets[@]}"
	fi
}

__tinygo-target() {
	if [[ ${#} -lt 1 ]]; then
		echo "error: no target specified"
		return 1
	fi
	target=( $( tinygo-targets ${@} ) )
	if [[ ${#target[@]} -lt 1 ]]; then
		echo "error: invalid target: ${@}"
		return 2
	elif [[ ${#target[@]} -gt 1 ]]; then
		echo "error: ambiguous target: ${@} (${target[@]})"
		return 3
	fi
	echo "${target[0]}"
}

tinygo-env() {
	if target=$( __tinygo-target ${@} ); then
		goos="$( tinygo info -target "${target}" | command grep -oP '^GOOS:\s+\K.+' )"
		printf 'export GOOS="%s"\n' "${goos}"
		export GOOS="${goos}"
		
		goarch="$( tinygo info -target "${target}" | command grep -oP '^GOARCH:\s+\K.+' )"
		printf 'export GOARCH="%s"\n' "${goarch}"
		export GOARCH="${goarch}"

		goflags="-tags=$( tinygo info -target "${target}" | command grep -oP '^build tags:\s+\K.+' | tr ' ' ',' )"
		printf 'export GOFLAGS="%s"\n' "${goflags}"
		export GOFLAGS="${goflags}"
	fi
}

tinygo-build-dfu-usage() {
	cat <<__USAGE__
USAGE

	tinygo-build-dfu [-h]
	tinygo-build-dfu -t TARGET [-o OUTPUT] SRC
	
FLAGS

	--help, -h     - this cruft
	--target, -t   - target device identifier (see notes)
	--output, -o   - the name of the output .dfu file (with or without extension)

ENVIRONMENT VARIABLES

	GOROOT         - the installation prefix to the real Go which TinyGo will
	                 need for building or referencing certain packages. must be
	                 a release version (not a development build).
	                 (default: ${GOROOT})

NOTES

    available TinyGo targets can be determined with command \`tinygo-targets\`.

__USAGE__
}

__tinygo-build-dfu-output() {
	if [[ ${#} -lt 1 ]]; then
		echo "error: no output file specified"
		return 1
	fi

	base=$( basename "${1}" ".dfu" )
	path=$( dirname "${1}" )
	full="${path}/${base}"
	
	if [[ -e "${full}" ]]; then
		if [[ -f "${full}" ]]; then
			if ! rm -f "${full}"; then
				echo "error: cannot overwrite output file: ${full}"
				return 3
			fi
		else
			echo "error: cannot overwrite output: not a regular file: ${full}"
			return 2
		fi
	fi
	if [[ -e "${full}.dfu" ]]; then
		if [[ -f "${full}.dfu" ]]; then
			if ! rm -f "${full}.dfu"; then
				echo "error: cannot overwrite output file: ${full}.dfu"
				return 3
			fi
		else
			echo "error: cannot overwrite output: not a regular file: ${full}.dfu"
			return 2
		fi
	fi
	echo "${full}"
}

tinygo-build-dfu() {
	
	local dfutool args target output

	if [[ $# -eq 0 ]]; then
		tinygo-build-dfu-usage
		return -1
	fi

	while test $# -gt 0
	do
		case "${1}" in
		(--help|-h)		tinygo-build-dfu-usage ; return -1 ;;
		(--target|-t)	shift ; target=${1} ;;
		(--output|-o)	shift ; output=${1} ;;
		(*)				args=( "${args[@]}" "$1" ) ;;
		esac
		shift
	done

	if [[ ${#args[@]} -eq 0 ]]; then
		echo "error: no Go source files provided (try --help|-h)"
		return 1
	fi

	if tinygo=$( which tinygo ); then
		if dfutool=$( which dfu-tool ); then
			if target=$( __tinygo-target "${target}" ); then
				if destout=$( __tinygo-build-dfu-output ${output} ); then
					if "${tinygo}" build -o="${destout}" -target="${target}" "${args[@]}"; then
						echo "compiled output executable: ${destout}"
						if "${dfutool}" convert dfu "${destout}" "${destout}.dfu"; then
							echo "converting executable to .dfu format: ${destout}.dfu"
						else
							echo "error: failed to convert executable to .dfu format: ${destout}.dfu"
							return 7
						fi
					else
						echo "error: failed to compile executable: target=${target}, output=${destout}" 
						return 6
					fi
				else
					echo "error: invalid output file: ${output}"
					return 5
				fi
			else
				echo "error: no target device"
				return 4
			fi
		else
			echo "error: required executable not found: dfu-tool"
			return 3
		fi
	else
		echo "error: required executable not found: tinygo"
		return 2
	fi
}

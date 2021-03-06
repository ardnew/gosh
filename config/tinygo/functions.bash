#!/bin/bash

SUBPAT='__FILE__' 
export CHECKSUM="sum ${SUBPAT}"
export TINYGO_CACHE="${HOME}/.tmp/tinygo.cache"

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

tinygo-target-env() {
	if target=$( __tinygo-target ${@} ); then
		# ensure we have a cache directory for target info
		[[ -d "${TINYGO_CACHE}" ]] || mkdir -p "${TINYGO_CACHE}"
		target_base="${target}.info"
		target_path="${TINYGO_CACHE}/${target_base}"
		target_info="${TINYGO_CACHE}/target.info"

		tinygo info -target "${target}" > "${target_path}"
		[[ -f "${target_info}" ]] && rm -f "${target_info}"
		ln -s "${target_base}" "${target_info}"

		tinygo-export-env
	fi
}

tinygo-export-env() {
	target_info="${TINYGO_CACHE}/target.info"
	if [[ -f "${target_info}" ]]; then
		if target=$( readlink -f "${target_info}" ); then
			printf "using tinygo target: %s\n" "$( basename "${target}" .info )"

			goos="$( command grep -oP '^GOOS:\s+\K.+' "${target_info}" )"
			printf 'export GOOS="%s"\n' "${goos}"
			export GOOS="${goos}"
		
			goarch="$( command grep -oP '^GOARCH:\s+\K.+' "${target_info}" )"
			printf 'export GOARCH="%s"\n' "${goarch}"
			export GOARCH="${goarch}"

			goflags="-tags=$( command grep -oP '^build tags:\s+\K.+' "${target_info}" | tr ' ' ',' )"
			printf 'export GOFLAGS="%s"\n' "${goflags}"
			export GOFLAGS="${goflags}"
		
			goroot="$( command grep -oP '^cached GOROOT:\s+\K.+' "${target_info}" )"
			printf 'editor GOROOT="%s"\n' "${goroot}"
			printf 'export GOROOT="%s"\n' "${GOBOOT}"
			export GOROOT="${GOBOOT}"
		fi
	fi
}

tinygo-subl() {
	target_info="${TINYGO_CACHE}/target.info"
	if [[ -f "${target_info}" ]]; then
		if target=$( readlink -f "${target_info}" ); then
			printf "using tinygo target: %s\n" "$( basename "${target}" .info )"

			goos="$( command grep -oP '^GOOS:\s+\K.+' "${target_info}" )"
			printf 'export GOOS="%s"\n' "${goos}"
			export GOOS="${goos}"
		
			goarch="$( command grep -oP '^GOARCH:\s+\K.+' "${target_info}" )"
			printf 'export GOARCH="%s"\n' "${goarch}"
			export GOARCH="${goarch}"

			goflags="-tags=$( command grep -oP '^build tags:\s+\K.+' "${target_info}" | tr ' ' ',' )"
			printf 'export GOFLAGS="%s"\n' "${goflags}"
			export GOFLAGS="${goflags}"
		
			goroot="$( command grep -oP '^cached GOROOT:\s+\K.+' "${target_info}" )"
			printf 'export GOROOT="%s"\n' "${goroot}"
			export GOROOT="${goroot}"

			subl "${@}"
		fi
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
	--check, -c    - compute checksum of output files (see notes)

ENVIRONMENT VARIABLES

	GOROOT         - the installation prefix to the real Go which TinyGo will
	                 need for building or referencing certain packages. must be
	                 a release version (not a development build).
	                 (default: "${GOROOT}")

	CHECKSUM       - the command used to compute checksums of a given file. a
	                 single-pass substitution is performed to replace any instance
	                 of the pattern \`${SUBPAT}\` with the actual file name.
	                 (default: "${CHECKSUM}")

NOTES

	available TinyGo targets can be determined with command \`tinygo-targets\`.

	checksum computations are performed using the command stored in environment 
	variable \$CHECKSUM, described in ENVIRONMENT VARIABLES above.

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
				echo "error: cannot overwrite output file (.dfu): ${full}.dfu"
				return 3
			fi
		else
			echo "error: cannot overwrite output (.dfu): not a regular file: ${full}.dfu"
			return 2
		fi
	fi
	echo "${full}"
}

tinygo-build-dfu() {
	
	local args tinygo dfutool target output destout checksum

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
		(--check|-c)    checksum=1 ;;
		(*)				args=( "${args[@]}" "$1" ) ;;
		esac
		shift
	done

	if [[ ${#args[@]} -eq 0 ]]; then
		echo "error: no Go source files provided (try --help|-h)"
		return 1
	fi

	echo "[ source   ] ${args[@]}"

	if ! tinygo=$( type -P tinygo ); then
		echo "error: required executable not found: tinygo"
		return 2
	fi

	echo "[ tinygo   ] ${tinygo}"

	if ! dfutool=$( which dfu-tool ); then
		echo "error: required executable not found: dfu-tool"
		return 3
	fi

	echo "[ dfu-tool ] ${dfutool}"

	if ! target=$( __tinygo-target "${target}" ); then
		echo "error: no target device"
		return 4
	fi

	echo "[ target   ] ${target}"

	# determine output file name by lexically analyzing source file paths if
	# user didn't specify one explicitly
	[[ -z ${output} ]] && output=$( tinygo-pkgname "${args[@]}" )

	# if analysis fails, output will remain undef
	if [[ -z ${output} ]]; then
		echo "error: output filename (-o) not provided"
		return 5
	fi

	if ! destout=$( __tinygo-build-dfu-output ${output} ); then
		echo "error: invalid output file: ${output}"
		return 6
	fi

	echo "[ output   ] ${destout}"

	build="${tinygo} build -o=${destout} -target=${target} -size=full ${args[@]}"

	echo "[ build    ] ${build}"

	if ! ${build}; then
		echo "error: failed to compile executable"
		return 7
	fi

	convert="${dfutool} convert dfu ${destout} ${destout}.dfu"

	echo "[ convert  ] ${convert}"

	if ! ${convert}; then
		echo "error: failed to convert executable to .dfu format: ${destout}.dfu"
		return 8
	fi

	if [[ -n ${checksum} ]]; then
		if [[ -z ${CHECKSUM} ]]; then
			echo "error: checksum command is undefined (try --help|-h)"
			return 9
		fi
		echo "[ checksum ] "$( $( echo "${CHECKSUM}" | perl -pe "s<\\Q${SUBPAT}\\E><${destout}.dfu>" ) )
	fi

	echo "[ success  ] ${destout}.dfu"
}

_tinygo-usage() {

	cmd="_tinygo"
	[[ ${#} -gt 0 ]] && cmd="tinygo-${1}"

	cat <<__USAGE__
USAGE

	${cmd} [-h]
	${cmd} -t TARGET SRC
	
FLAGS

	--help, -h          - this cruft
	--command, -c       - tinygo subcommand to run
	--target, -t        - target device identifier (see notes)
	--programmer, -p    - programmer used for flash/debug
	--output, -o        - output filename (default basename of source pkg)
	--hex, -x           - generate Intel .hex file from output ELF

ENVIRONMENT VARIABLES

	GOROOT              - the installation prefix to the real Go which TinyGo
	                      will need for building and referencing packages.
	                      must be a release version (not a development build).
	                        (default: "${GOROOT}")

NOTES

	available TinyGo targets can be determined with command \`tinygo-targets\`.

__USAGE__
}

_tinygo() {

	local args tinygo subcmd target programmer output hex

	while test $# -gt 0
	do
		case "${1}" in
		(--help|-h)			_tinygo-usage ${SUBCMD} ; return -1 ;;
		(--command|-c)		shift ; subcmd=${1} ;;
		(--target|-t)		shift ; target=${1} ;;
		(--programmer|-p)	shift ; programmer=${1} ;;
		(--output|-o)		shift ; output=${1} ;;
		(--hex|-x)			hex=1 ;;
		(*)					args=( "${args[@]}" "$1" ) ;;
		esac
		shift
	done

	if [[ ${#args[@]} -eq 0 ]]; then
		echo "error: no Go source files provided (try --help|-h)"
		return 1
	fi

	echo "[ source   ] ${args[@]}"

	if ! tinygo=$( type -P tinygo ); then
		echo "error: required executable not found: tinygo"
		return 2
	fi

	echo "[ tinygo   ] ${tinygo}"

	cmd=( "${tinygo}" )

	[[ -z ${subcmd} ]] && subcmd="build"

	cmd=( "${cmd[@]}" "${subcmd}" )

	if [[ -z ${target} ]]; then
		target_info="${TINYGO_CACHE}/target.info"
		if [[ -f "${target_info}" ]]; then
			if target_path=$( readlink -f "${target_info}" ); then
				target=$( basename "${target_path}" .info )
			fi
		fi
	fi

	if ! target=$( __tinygo-target "${target}" ); then
		echo "error: no target device"
		return 3
	fi

	echo "[ target   ] ${target}"

	cmd=( "${cmd[@]}" -target="${target}" )

	case "${subcmd}" in
		(build) 
			pkg=$( tinygo-pkgname "${args[@]}" )
			[[ -z ${output} ]] && output="${pkg}"
			if [[ -z ${output} ]]; then
				echo "error: output filename (-o) not provided"
				return 4
			fi
			cmd=( "${cmd[@]}" -size="full" -opt=1 -o="${output}" )
			;;
		(gdb)
			[[ -z ${programmer} ]] && programmer="jlink"
			cmd=( "${cmd[@]}" -size="full" -opt=1 -programmer="${programmer}" )
			;;
	esac

	[[ -n ${CFLAGS} ]] && cmd=( "${cmd[@]}" -cflags="${CFLAGS}" )

	cmd=( "${cmd[@]}" "${args[@]}" )

	echo "[ command  ] ${cmd[@]}"

	if ! "${cmd[@]}"; then
		echo "error: command failed"
		return 5
	fi

	if [[ -n ${hex} ]] && [[ "${hex}" != "0" ]]; then
		if [[ -z ${output} ]]; then
			echo "error: no output ELF file to generate .hex file"
			return 6
		fi
		if [[ ! -d "${TINYGOROOT}" ]]; then
			echo "error: invalid or unset TINYGOROOT"
			return 7
		fi
		cmd=( "${TINYGOROOT}/llvm-build/bin/llvm-objcopy" -O "ihex" -R ".eeprom" "${output}" "${output}.hex" )
		echo "[ objcopy  ] ${cmd[@]}"
		if ! "${cmd[@]}"; then
			echo "error: command failed"
			return 8
		fi
	fi
}

tinygo-gdb()   { SUBCMD="gdb"   _tinygo -c gdb   ${@}; }
tinygo-build() { SUBCMD="build" _tinygo -c build ${@}; }

tinygo-pkgname() {
	src=()
	while test $# -gt 0; do
		if [[ -e "${1}" ]]; then
			s=$( filepath.EvalSymlinks "${1}" )
			s=$( filepath.Abs "${s}" )
			src=( "${src[@]}" "${s}" )
		fi
		shift
	done
	if [[ ${#src[@]} -gt 0 ]]; then
		name=$( lcpre "${src[@]}" )
		[[ -f "${name}" ]] && name=$( dirname "${name}" )
		basename "${name}"
	fi
}


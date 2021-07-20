#!/bin/bash

# ==============================================================================
#  NOTE: see file defines.bash for additional functions used by startup
# ==============================================================================

profiles() {
	# print all of the currently active gosh profiles
	perl -nle '
		while (/(\((.*)\))|$/) {
			printf "%d: %s$/", $n++, $`;
			last unless $_ = $2
		}
	' <<< "${GOSH_PROFILE}"
}

cd() {
	if [[ $# -gt 0 ]]; then
		if ! pushd "${@}" &> /dev/null; then
			printf -- 'cd: failed to change directory: %s\n' "${@}"
		fi
	else
		if ! pushd "${HOME}" &> /dev/null; then
			printf -- 'cd: failed to change directory: HOME=%s\n' "${HOME}"
		fi
	fi
}

cb() {
	if ! popd "${@}" &> /dev/null; then
		printf -- 'cb: failed to pop directory stack\n'
	fi
}

up() {
	if [[ "${PWD}" = '/' ]]; then
		printf -- 'up: no parent directory\n'
	else
		path="${PWD}"
		parent='..'
		while ! pushd "${parent}" &> /dev/null; do
			[[ "${path}" = '/' ]] && return -1
			path=$( dirname "${path}" )
			parent="${path}"
		done
	fi
}

# isset verifies a given environment variable is defined AND that it does not
# have a false-like value. False-like is defined as follows:
# || Contains precisely 1 string of FALSE (surrounded by 0 or more whitespace), 
# || where FALSE is one of the following:
# ||   - the empty string ""
# ||   - "false" (case-insensitive)
# ||   - 1 or more zeroes ("0", "00", "000", etc.)
isset() { 
	# Pass variable NAME as argument, not value. For example:
	#   isset GOPATH        <- ok!
	#   isset $GOPATH       <- WRONG
	[[ ${#} -gt 0 ]] && [[ -n ${!1} ]] && 
		command grep -qviP '^\s*(false|0+)?\s*$' <<< "${!1}"
}

abspath() {
	# use PWD if no argument provided
	local path="${PWD}"
	[[ ${#} -gt 0 ]] && path="${1}"
	# several different ways to obtain the absolute path to a file, but not all
	# systems have all of these tools. check for preferred tooling in-order
	# until one is found.
	abs=( 
		'filepath.Abs'  ''    # goshfun
		'realpath'      '-mP' # newer coreutils
		'readlink'      '-f'  # older coreutils
	)
	for (( i = 0; i < ${#abs[@]}; i += 2 )); do
		local -a cmd=( "${abs[${i}]}" ) 
		[[ ${#abs[((i+1))]} -gt 0 ]] && 
			cmd+=( "${abs[((i+1))]}" ) # append args if non-empty
		type -t "${cmd[0]}" &> /dev/null &&
			"${cmd[@]}" "${path}" 2> /dev/null && break
	done
}

exepath() {	
	abspath "${0}"
}

exedir() { 
	dirname "$( exepath )"
}

detach() {
	[[ ${#} -gt 0 ]] || return
	nohup "${@}" &> /dev/null &
}

manbuiltin() {
	# easy access to bash built-ins
	man bash | less -p "^ {4,7}$1 "
	#help $1 # another potential doc source
}

useshopt() {
	local isset=$( shopt "${1}" > /dev/null ; printf $? )
	shopt -s "${1}" ; "${@:2}"
	[[ 1 == "${isset}" ]] && shopt -u "${1}"
}

ignorecase() {
	useshopt "nocasematch" "$@"
}

dos2unix() {
	if type -P dos2unix > /dev/null; then
		command dos2unix "$@"
	else
		perl -pi -e 's/\r\n|\n|\r/\n/g' "$@"
	fi
}

unix2dos() {
	if type -P unix2dos > /dev/null; then
		command unix2dos "$@"
	else
		perl -pi -e 's/\r\n|\n|\r/\r\n/g' "$@"
	fi
}

unixtime2date() {
	if [[ $# -gt 0 ]]; then
		local seconds=${1}
		if [[ $seconds -gt 86400 ]]; then # seconds in a day
			printf "%d days " $(( seconds / 86400 ))
		fi
		date -d "1970-01-01 + $seconds seconds" "+%H hrs %M min %S sec"
	fi
}

now() {
	date +'%Y%m%d-%H%M%S'
}

stamp() {
	# use a common timestamp for all arguments
	if now=$( now ); then
		for path in "${@}"; do
			if [[ -e "${path}" ]]; then
				# ensure we don't have trailing slashes or other nonsense that might
				# cause the destination path to be malformed.
				cpath=$( filepath.Clean "${path}" )
				# check if file already contains timestamp, and replace it if so
				ext=$( filepath.Ext "${cpath}" )
				dest=${cpath}
				# regex based on date format from function now()
				if [[ "${ext}" =~ ^\.[0-9]{8}-[0-9]{6}$ ]]; then
					dest=$( strings.TrimSuffix "${dest}" "${ext}" )
				fi
				mv "${cpath}" "${dest}.${now}"
				echo "${dest}.${now}"
			else
				erro "ignore: no such file or directory: ${path}"
				return 1
			fi
		done
	else
		ret=${?}
		erro "error: cannot create timestamp"
		return ${ret}
	fi
}

unstamp() {
	for path in "${@}"; do
		if [[ -e "${path}" ]]; then
			# ensure we don't have trailing slashes or other nonsense that might
			# cause the pattern match to fail.
			cpath=$( filepath.Clean "${path}" )
			ext=$( filepath.Ext "${cpath}" )
			# regex based on date format from function now()
			if [[ "${ext}" =~ ^\.[0-9]{8}-[0-9]{6}$ ]]; then
				dest=$( strings.TrimSuffix "${cpath}" "${ext}" )
				mv "${cpath}" "${dest}"
				echo "${dest}"
			else
				erro "ignore: file extension is not a timestamp: ${path}"
				return 2
			fi
		else
			erro "ignore: no such file or directory: ${path}"
			return 1
		fi
	done
}

rgb2hex() {
	perl -le 'printf"0x%02X%02X%02X$/",map{($_<=1.0&&$_>=0.0)?int($_*255+0.5):$_}@ARGV' $@
}

hex2rgb() {
	perl -le '@_=map{oct("0x$_")/0xFF}(shift=~/../g);print"@_[@_-3..$#_]"' $@
}

clipboard-filter() {
	xclip -selection clipboard -o | "${@}" |
		tee >( xclip -selection clipboard -i )
}

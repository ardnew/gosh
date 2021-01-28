#!/bin/bash

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

escape() {
	# escape bash metachars
	local args="$@"
	printf "$args" | sed -e "s/'/'\\\\''/g; 1s/^/'/; \$s/\$/'/"
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

rgb2hex() {
	perl -le 'printf"0x%02X%02X%02X$/",map{($_<=1.0&&$_>=0.0)?int($_*255+0.5):$_}@ARGV' $@
}

hex2rgb() {
	perl -le '@_=map{oct("0x$_")/0xFF}(shift=~/../g);print"@_[@_-3..$#_]"' $@
}

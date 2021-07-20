#!/bin/bash

escape() {
	# escape bash metachars
	local args="$@"
	printf "$args" | sed -e "s/'/'\\\\''/g; 1s/^/'/; \$s/\$/'/"
}

joinstr() { 
	local d=${1-} f=${2-}
	if shift 2; 
		then printf %s "$f" "${@/#/$d}"
	fi
}

uniqstr() {
	local pl='
use strict;
use warnings;

my %s;
END { print for sort { $s{$a} <=> $s{$b} } keys %s }
while (<>) {
	s/[\r\n]+$//sg; $s{$_} = $. unless exists $s{$_}
}
'
	if [[ $# -gt 0 ]]; then
		if [[ -f "${1}" ]]; then
			perl -le "${pl}" "${@}"
		else
			perl -le "${pl}" <<< "$( joinstr $'\n' "${@}" )"
		fi
	else
		perl -le "${pl}"
	fi
}

# uniqpath echoes each path from the given colon-delimited list(s) of paths
# which does not already exist in the path env var with the given name.
# Example - determine if some common bin paths are already in $PATH: 
#   uniqpath PATH /usr/local/bin ${HOME}/.bin:${HOME}/.local/bin
uniqpath() {
	[[ ${#} -gt 1 ]] || return
	var=${1}
	shift
  # process each argument independently
  for arg in "${@}"; do
    # echo each element in the ":"-delimited list arg that is not also in var
		while read -re path; do
			# surround var with colons so that we don't have to handle path existing
			# at the beginning or end of the list as special cases.
			[[ ":${!var}:" == *":${path}:"* ]] || echo "${path}"
		done < <( echo "${arg}" | tr ':' '\n' )
	done
}

# relpath constructs a relative path from the first argument to the second.
# if only one path is given, the first argument is assumed to be PWD.
relpath() {
	pl=( perl -MFile::Spec::Functions=abs2rel )
	local src dst=${1}
	if [[ $# -gt 1 ]]; then
		src=${1} dst=${2}
	fi
	[[ -n ${dst} ]] && 
		"${pl[@]}" -le 'print abs2rel(@ARGV)' "${dst}" "${src}"
}

# prepath echoes the colon-delimited path env var with given name, prepended
# with each path in the given colon-delimited list(s) of paths. If a path in the
# given list already exists in the env var path, then it is removed from its
# position in the env var, and prepended to the resulting list.
prepath() {
	[[ ${#} -gt 1 ]] || return
	var=${1}
	shift
	# build a path list from all given path lists
	pre=$( joinstr ':' "${@}" ) 
	# prune any given paths from the specified environment variable
	base=( $( uniqpath pre "${!var}" ) )
	# prepend the unique given path lists to the pruned env var
	joinstr ':' "${pre}" "${base[@]}"
}

# goshconfig prints the default path to the gosh configuration file. this path
# is determined by parsing the output of command "gosh --help". If the -d flag
# is given, prints only the directory path containing the configuration file.
goshconfig() {
	path=$( gosh --help 2>&1 | command grep -A 1 -- '-f path' | tail -n 1 | 
		command grep -oP 'default "\K[^"]+' )
	if [[ ${#} -gt 0 ]] && [[ "${1}" == '-d' ]]; then
		dirname "${path}"
	else
		echo "${path}"
	fi
}

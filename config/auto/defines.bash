#!/bin/bash

# define is syntactic sugar for assigning HEREDOC content to a variable. 
# Works with quoted content (e.g., define foo <<'EOF' ...), as well as scripts
# that set -e (since read returns non-zero on success).
define() { IFS='\n' read -r -d '' ${1} || true; }

# escape prints the given arguments in a quoted format that can be reused as
# input to other bash commands.
escape() {
	# instead of printf %q, you can also use parameter expansion: ${foo@Q}
	if [[ $# -gt 0 ]]; then
		if [[ -f "${1}" ]] && [[ -r "${1}" ]]; then
			for v in "${@}"; do
				[[ -e "${v}" ]] && printf -- '%q\n' "$( cat "${v}" )"
			done
		else
			for v in "${@}"; do
				printf -- '%q\n' "${v}"
			done
		fi
	else
		printf -- '%q\n' "$( cat - )"
	fi
} 

joinstr() { 
	local d=${1-} f=${2-}
	if shift 2; 
		then printf %s "$f" "${@/#/$d}"
	fi
}

# uniqstr prints each unique string in the given input. Input may be provided
# as arguments (delimited per argument, not per word in each argument), path to
# a readable file, or via stdin (e.g., pipe, file redirect, etc.). In the latter
# two cases (file and stdin), strings are delimited per line.
uniqstr() {
	define uniq <<'PL'
use strict;
use warnings;

my %s;
END { print for sort { $s{$a} <=> $s{$b} } keys %s }
while (<>) {
	s/[\r\n]+$//sg; $s{$_} = $. unless exists $s{$_}
}
PL
	if [[ $# -gt 0 ]]; then
		if [[ -f "${1}" ]] && [[ -r "${1}" ]]; then
			perl -le "${uniq}" "${@}"
		else
			perl -le "${uniq}" <<< "$( joinstr $'\n' "${@}" )"
		fi
	else
		perl -le "${uniq}"
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
# is determined by parsing the output of help command "gosh -h". If the -d flag
# is given, prints only the directory path containing the configuration file.
goshconfig() {
	# locate the path by parsing the default value for the "-f" flag identified at
	# the end of the flag description in the output of "gosh -h". We don't know
	# how many lines or the exact format this flag will have in the output, so we
	# have to identify and store lines in a buffer before trying to match.
	define parse <<'PL'
use strict;
use warnings;
my ($k, $t);
print join(" ",	grep { 
		$k = defined $t && $k != /^${t}-\S/ || (($t) = /^(\s+)-f\s+\S+/g) 
	} <> ) =~ 
		/[\(\[]?\s*default:?\s*["'\'']?(.*?)(?=["'\'']?\s*[\)\]]?\s*$)/ig
PL
	path=$( gosh --help 2>&1 | perl -le "${parse}" )

	if [[ ${#} -gt 0 ]] && [[ "${1}" == '-d' ]]; then
		echo "${path%/*}" 
	else
		echo "${path}"
	fi
}

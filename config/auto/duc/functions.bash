#!/bin/bash

duc_bin="duc"
duc_path=$( which "${duc_bin}" )
duc_index_cmd="index"

index-usage() {
	printf -- 'create or update disk usage index of a directory tree\n'
	printf -- 'usage:\n'
	printf -- '\t%s [-bdpvu] VOLUME\n' "${duc_index_cmd}"
	printf -- '\t%s -h\n' "${duc_index_cmd}"
	printf -- '\n'
	printf -- '\t-b      - bytes: show file size in exact number of bytes\n'
	printf -- '\t-d      - dry-run: do not update database, just crawl\n'
	printf -- '\t-h      - help: display this cruft\n'
	printf -- '\t-p      - progress: show progress during indexing\n'
	printf -- '\t-u      - ui: browse index with ncurses user interface\n'
	printf -- '\t-v      - verbose: show all executed commands and output\n'
	printf -- '\n'
	return -1
}

timestamp() { date +'%Y%m%d-%H%M%S'; }

index-volumes() {
	local known=()
	for (( i = 0; i < ${#duc_volume[@]}; i += 2 )); do
		volume="${duc_volume[${i}]}"
		#path="${duc_volume[$(( i + 1 ))]}"
		known=( "${known[@]}" "${volume}" )
	done
	echo "${known[@]}"
}

index() {

	local parse=1
	local arg_bytes arg_dryrun arg_help arg_progress arg_verbose arg_ui
	local args=() # remaining command-line args after removing parsed options

	# parse command line arguments for any single-character flags. these
	# may be given individually or combined (e.g., "-d -b" == "-bd"), in
	# any order. arguments without leading hyphen are retained in $args,
	# and passed on to the given CMD verbatim.
	while test $# -gt 0; do
		if [[ -n $parse ]]; then
			if [[ "$1" == "--" ]]; then
				unset -v parse

			elif [[ "$1" == -* ]]; then
				while read -re -n1 c; do
					case "$c" in
					(b) # bytes: show file size in exact number of bytes
						arg_bytes=1
						;;
					(d) # dry-run: do not update database, just crawl
						arg_dryrun=1
						;;
					(h) # help: display this cruft
						arg_help=1
						;;
					(p) # progress: show progress during indexing
						arg_progress=1
						;;
					(u) # ui: browse index with ncurses user interface
						arg_ui=1
						;;
					(v) # verbose: show all executed commands and output
						arg_verbose=1
						;;
					(*)
						echo "unrecognized flag: -${c}" >&2
						;;
					esac
				done < <( printf -- '%s' "$1" | sed -E 's/^-+//' )
			else
				unset -v parse
			fi
		fi

		if [[ -z $parse ]]; then
			args=( "${args[@]}" "$1" )
		fi
		shift
	done

	retval=0
	if [[ -n $arg_help ]]; then
		index-usage
		retval="${?}"
	elif [[ ${#args[@]} -eq 0 ]]; then
		printf -- 'error: no volume specified: volumes: %s (see -h for usage)\n' "$( index-volumes )"
		retval=0
	else
		if [[ -z ${duc_path} ]]; then
			printf -- 'error: command not found: %s\n' "${duc_bin}"
			retval=1
		else
			if [[ -n ${arg_ui} ]]; then
				cmd=( "${duc_path}" "ui" )
				[[ -n $arg_bytes ]]    && cmd=( "${cmd[@]}" "--bytes" )
			else
				cmd=( "${duc_path}" "index" "--one-file-system" )
				[[ -n $arg_bytes ]]    && cmd=( "${cmd[@]}" "--bytes" )
				[[ -n $arg_dryrun ]]   && cmd=( "${cmd[@]}" "--dry-run" )
				[[ -n $arg_progress ]] && cmd=( "${cmd[@]}" "--progress" )
			fi
			for arg in "${args[@]}"; do
				local found
				for (( i = 0; i < ${#duc_volume[@]}; i += 2 )); do
					volume="${duc_volume[${i}]}"
					path="${duc_volume[$(( i + 1 ))]}"
					if [[ "${arg}" == "${volume}" ]]; then
						found=1
						sudo ${cmd[@]} --database="${path}/${duc_database_name}" "${path}"
					fi
				done
				if [[ -z ${found} ]]; then
					printf -- 'error: unrecognized volume: %s (volumes: %s)\n' "${arg}" "$( index-volumes )"
				fi
			done
		fi
	fi
	return "${retval}"
}

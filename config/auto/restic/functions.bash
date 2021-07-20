#!/bin/bash

restic() {

	if [[ -z ${RESTIC_BIN} ]]; then
		echo "error: restic is not installed or not found"
		return -1
	fi

	local -a gargs=(
		--repository-file="${RESTIC_REPOSITORY_FILE}" 
		--password-file="${RESTIC_PASSWORD_FILE}" 
	) # global arguments always used regardless of command

	local -a cargs=() # command arguments
	local cmd

	# Assign all arguments with a leading "-" that appear before the command 
	# argument (without a leading "-") to gargs. All arguments that appear after
	# the command are placed in cargs.
	while [[ ${#} -gt 0 ]]; do
		if [[ -z ${cmd} ]]; then
			if [[ ${1} =~ ^--?[^[:space:]]+ ]]; then
				gargs+=( ${1} )
			else
				cmd=${1}
			fi
		else
			cargs+=( ${1} )
		fi
		shift
	done

	if [[ -z ${cmd} ]]; then
		gargs=()
		cargs=()
		cmd='help'
	fi

	if [[ -z ${RESTIC_REPOSITORY_FILE} ]]; then
		echo "error: repository file undefined: RESTIC_REPOSITORY_FILE"
		return 10
	elif [[ ! -f "${RESTIC_REPOSITORY_FILE}" ]]; then
		echo "error: repository file not found: ${RESTIC_REPOSITORY_FILE}"
		return 11
	fi

	if [[ -z ${RESTIC_PASSWORD_FILE} ]]; then
		echo "error: password file undefined: RESTIC_PASSWORD_FILE"
		return 20
	elif [[ ! -f "${RESTIC_PASSWORD_FILE}" ]]; then
		echo "error: password file not found: ${RESTIC_PASSWORD_FILE}"
		return 21
	fi

	sudo -E "${RESTIC_BIN}" "${gargs[@]}" ${cmd} "${cargs[@]}"
}

restic-backup() {

	if [[ -z ${RESTIC_BIN} ]]; then
		echo "error: restic is not installed or not found"
		return -1
	fi

	if [[ -z ${RESTIC_INCLUDES_FILE} ]]; then
		echo "error: includes file undefined: RESTIC_INCLUDES_FILE"
		return 30
	elif [[ ! -f "${RESTIC_INCLUDES_FILE}" ]]; then
		echo "error: includes file not found: ${RESTIC_INCLUDES_FILE}"
		return 31
	fi

	if [[ -z ${RESTIC_EXCLUDES_FILE} ]]; then
		echo "error: excludes file undefined: RESTIC_EXCLUDES_FILE"
		return 40
	elif [[ ! -f "${RESTIC_EXCLUDES_FILE}" ]]; then
		echo "error: excludes file not found: ${RESTIC_EXCLUDES_FILE}"
		return 41
	fi

	restic backup                                     \
		--one-file-system                               \
		--files-from="${RESTIC_INCLUDES_FILE}"          \
		--exclude-file="${RESTIC_EXCLUDES_FILE}"
}

#!/bin/bash

case "${host_kind}" in
	$host_linux)
		path_rustup="/usr/lib/rustup"
		path_cargo="/usr/lib/cargo"
		;;
	$host_darwin)
		;;
	$host_cygwin)
		;;
	$host_mswsl)
		;;
	*)
		;;
esac

RUSTUP_HOME="${path_rustup}"
CARGO_HOME="${path_cargo}"
PATH="${CARGO_HOME}/bin:${PATH}"

# add the rustup manpages to our system MANPATH
if [[ -d "${path_rustup}" ]]; then
	if [[ -n "${target_triple}" ]]; then
		rust_tools=( "${path_rustup}/toolchains/"*"-${target_triple}" )
		if [[ ${#rust_tools[@]} -gt 0 ]]; then
			rust_man=$( strings.Join "${rust_tools[@]/%//share/man}" ":" )
		fi
	fi
fi

[[ -n ${rust_man} ]] && \
	MANPATH="${rust_man}:${MANPATH}"

export RUSTUP_HOME CARGO_HOME PATH MANPATH

#!/bin/bash
# indicate our inclusion to all who follow
__gosh_paths="paths.bash"
__gosh_paths_includes=$( basename "${__gosh_paths}" ".bash" )".d"

# source all files in the includes directory
if [[ -d "${__gosh_paths_includes}" ]]; then
	for inc in "${__gosh_paths_includes}"/*; do
		. "${inc}"
	done
fi

case "${host_kind}" in
	$host_linux)
		path_go="${HOME}/Code/go"
		path_nvim="${HOME}/.config/nvim"
		path_goshfun="${HOME}/.local/bin/gosh"
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

GOPATH="${path_go}"
VIM="${path_vim}"

export GOPATH VIM

PATH="${HOME}/.local/bin:${GOPATH}/bin:/usr/local/bin:${PATH}"

[[ -d "${path_goshfun}" ]] && \
	PATH="${path_goshfun}:${PATH}"

LD_LIBRARY_PATH="${HOME}/.local/lib:/usr/local/lib:${LD_LIBRARY_PATH}"

export PATH LD_LIBRARY_PATH

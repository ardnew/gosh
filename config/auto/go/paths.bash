#!/bin/bash

case "${target_triple}" in
	aarch64-unknown-linux-gnu)
		os_go="linux"
		arch_go="arm64"
		;;
	x86_64-unknown-linux-gnu)
		os_go="linux"
		arch_go="amd64"
		;;
esac

case "${host_kind}" in
	${host_linux})
		root_go="/usr/local/go/dev"
		path_go="/usr/local/go"
		path_goshfun="${HOME}/.local/bin/gosh"
		;;
	${host_darwin})
		root_go="/usr/local/go/dev"
		path_go="/usr/local/go"
		path_goshfun="${HOME}/.local/bin/gosh"
		;;
	${host_cygwin})
		;;
	${host_mswsl})
		;;
	*)
		;;
esac

if [[ -d "${root_go}" ]]; then
	GOROOT="${root_go}"
	PATH="${GOROOT}/bin:${PATH}"
fi

if [[ -d "${path_go}" ]]; then
	GOPATH="${path_go}"
	PATH="${GOPATH}/bin:${PATH}"
fi

[[ -n ${os_go}   ]] && GOOS="${os_go}"
[[ -n ${arch_go} ]] && GOARCH="${arch_go}"

[[ -d "${path_goshfun}" ]] && PATH="${path_goshfun}:${PATH}"

export GOOS GOARCH GOROOT GOPATH PATH

#!/bin/bash

host_linux=1
[[ "${OSTYPE}" = *linux* ]] &&
	host_kind=${host_linux}

host_darwin=2
[[ "${OSTYPE}" = *darwin* ]] &&
	host_kind=${host_darwin}

host_cygwin=3
[[ "${OSTYPE}" = *cygwin* ]] &&
	host_kind=${host_cygwin}

host_freebsd=4
[[ "${OSTYPE}" = *freebsd* ]] &&
	host_kind=${host_freebsd}

host_mswsl=5
[[ "$( uname -a | tr '[:upper:]' '[:lower:]' )" =~ microsoft ]] &&
	host_kind=${host_mswsl}

is-host-linux()   { return ${host_kind} -eq ${host_linux}; }
is-host-darwin()  { return ${host_kind} -eq ${host_darwin}; }
is-host-cygwin()  { return ${host_kind} -eq ${host_cygwin}; }
is-host-freebsd() { return ${host_kind} -eq ${host_freebsd}; }
is-host-mswsl()   { return ${host_kind} -eq ${host_mswsl}; }

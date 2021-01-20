#!/bin/bash

host_linux=1
host_darwin=2
host_cygwin=3
host_freebsd=4
host_mswsl=5

uname_lower=$( uname -a | tr '[:upper:]' '[:lower:]' )

if [[ "${OSTYPE}" = *linux* ]]; then
  host_kind=${host_linux}
elif [[ "${OSTYPE}" = *darwin* ]]; then
  host_kind=${host_darwin}
elif [[ "${OSTYPE}" = *cygwin* ]]; then
  host_kind=${host_cygwin}
elif [[ "${OSTYPE}" = *freebsd* ]]; then
  host_kind=${host_freebsd}
elif [[ "${uname_lower}" =~ microsoft ]]; then
  host_kind=${host_mswsl}
fi

is-host-linux()   { return ${host_kind} -eq ${host_linux}; }
is-host-darwin()  { return ${host_kind} -eq ${host_darwin}; }
is-host-cygwin()  { return ${host_kind} -eq ${host_cygwin}; }
is-host-freebsd() { return ${host_kind} -eq ${host_freebsd}; }
is-host-mswsl()   { return ${host_kind} -eq ${host_mswsl}; }

if [[ "${OSTYPE}" = *linux-gnu* ]]; then
	if [[ "${uname_lower}" = *x86_64* ]]; then
		target_triple="x86_64-unknown-linux-gnu"
	elif [[ "${uname_lower}" = *aarch64* ]]; then
		target_triple="aarch64-unknown-linux-gnu"
	fi
fi


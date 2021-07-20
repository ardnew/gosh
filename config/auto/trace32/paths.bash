#!/bin/bash

case "${target_triple}" in
	x86_64-unknown-linux-gnu)
		t32_host='pc_linux64'
		;;
esac

case "${host_kind}" in
	${host_linux})
		root_t32="/usr/local/lib/trace32"
		path_t32="${root_t32}/bin/${t32_host}"
		license_t32="${root_t32}/license.t32"
		settings_t32="${root_t32}/system-settings.cmm"
		;;
	${host_darwin})
		;;
	${host_cygwin})
		;;
	${host_mswsl})
		;;
	*)
		;;
esac


if [[ -d "${path_t32}" ]]; then
	# host path contains both executables and shared object libs
	PATH="${path_t32}:${PATH}"
	LD_LIBRARY_PATH="${path_t32}:${LD_LIBRARY_PATH}"
fi

export PATH LD_LIBRARY_PATH

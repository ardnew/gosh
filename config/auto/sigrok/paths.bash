#!/bin/bash

case "${host_kind}" in
	$host_linux)
		path_sigrok='/usr/local/sigrok'
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

# add the sigrok paths to the respective environment variables
if [[ -d "${path_sigrok}" ]]; then
	# executable path
	[[ -d "${path_sigrok}/bin" ]] && 
		PATH=$( prepath PATH "${path_sigrok}/bin" )
	# linker library path
	[[ -d "${path_sigrok}/lib" ]] && 
		LD_LIBRARY_PATH=$( prepath LD_LIBRARY_PATH "${path_sigrok}/lib" )
	# pkg-config path
	[[ -d "${path_sigrok}/lib/pkgconfig" ]] && 
		PKG_CONFIG_PATH=$( prepath PKG_CONFIG_PATH "${path_sigrok}/lib/pkgconfig" )
	# man page path
	[[ -d "${path_sigrok}/share/man" ]] && 
		MANPATH=$( prepath MANPATH "${path_sigrok}/share/man" )
	# python2 module path
	py=$( basename "$( readlink -f "$( which python2 )" )" 2>/dev/null )
	[[ -d "${path_sigrok}/lib/${py}/site-packages" ]] && 
		PYTHONPATH=$( prepath PYTHONPATH "${path_sigrok}/lib/${py}/site-packages" )
fi

export PATH LD_LIBRARY_PATH PKG_CONFIG_PATH MANPATH PYTHONPATH

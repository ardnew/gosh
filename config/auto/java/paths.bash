#!/bin/bash

case "${host_kind}" in
	$host_linux)
		jdk_path="/opt/oracle/jdk"
		java_home="${jdk_path}"
		jre_home="${jdk_path}/jre"
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

if [[ -d "${jdk_path}" ]]; then
	JAVA_HOME="${java_home}"
	JRE_HOME="${jre_home}"
fi

export JAVA_HOME JRE_HOME

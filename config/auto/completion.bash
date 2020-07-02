#!/bin/bash

# ==============================================================================
#
#  file: completion.bash
#
#  date: 19 June 2020
#
#  auth: andrew@ardnew.com
#
#  desc: shell auto-completion configuration
#
# ==============================================================================

global_bash_completion="/usr/share/bash-completion/bash_completion"
system_bash_completion="/etc/bash_completion"

if ! shopt -oq posix; then
  if [ -f "${global_bash_completion}" ]; then
    . "${global_bash_completion}"
  elif [ -f "${system_bash_completion}" ]; then
    . "${system_bash_completion}"
  fi
fi

complete -C ${GOPATH}/bin/gocomplete go


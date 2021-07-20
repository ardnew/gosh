#!/bin/bash

openocd_path='/usr/local/openocd'
openocd_bin="${openocd_path}/bin/openocd"
openocd_src="${openocd_path}/share/openocd/scripts"

gdb_bin=$( which gdb-multiarch )

dashboard_init="${HOME}/.config/gosh/share/gdb-dashboard/dashboard.gdbinit"
dashboard_style="${HOME}/.config/gosh/share/gdb-dashboard/style"

gdb_opt_init="--init-command=" # after loading inferior
#gdb_opt_init="--command="      # before loading inferior

__openocd-gdb-options()
{
  tcpport="3333"

  symbols=$1
  if [[ -f "$symbols" ]]
  then
    perl -le "print STDERR 'using symbols from file: $symbols'"
    shift

    symdir=$( readlink -f "$symbols" )
    symdir=$( dirname "$symdir" )

    gdbinit=$( mktemp -q -p "$symdir" -t "$( basename $symbols ).XXXXX.gdbinit" )

    # configure the default gdbinit options
    delaysec=0.2
    cat <<GDB >> "$gdbinit"
target extended-remote localhost:$tcpport
monitor reset halt
shell sleep ${delaysec}
monitor adapter speed 4000
file "${symbols}"
load
shell sleep ${delaysec}
monitor reset init
shell sleep ${delaysec}
break Reset_Handler
GDB
#monitor reset init
#monitor reset halt
#shell sleep ${delaysec}

    echo $gdbinit
    return 0

  else
    perl -le "print STDERR 'error: no symbols file (.elf) provided'"
  fi
  return 1
}

openocd-gdb-dashboard()
{
  if [[ ${#} -lt 1 ]]; then
    echo $'usage:\n\topenocd-gdb-dashboard exe-file [style-file]'
    echo
    echo $'style-file should contain one line per window attribute, formatted'
    echo $'as "window: attribute value". comments and empty lines are ignored.'
    echo $'for example:'
    echo
    echo $'\t# set source window height to 24 lines'
    echo $'\tsource: height 24'
    echo
    return 1
  fi
  style="${dashboard_style}"
  gdbinit=$( __openocd-gdb-options ${1} )
  [[ $? -eq 0 ]] || return $?
  if [[ $# -gt 1 ]]; then
    shift # symbols
    if [[ -f "${1}" ]]; then
      style="${1}" # use style file if provided
      shift
    fi
    gdb_args=( "${@}" )
  fi

  # create another init script for configuring the dashboard in our current tmux
  # window TTY
  layout_init="${HOME}/.gdbinit.d/100-dashboard"

  local id="$( tmux split-pane -hPF  "#D" "tail -f /dev/null")"
  tmux last-pane
  local tty="$(tmux display-message -p -t "$id" '#{pane_tty}')"

  # ensure the path exists to directory of init scrips
  layout_init_path=$( dirname "${layout_init}" )
  [[ -d "${layout_init_path}" ]] || mkdir -p "${layout_init_path}"

  # use our current tmux TTY for dashboard init
  cat <<LAYOUTINIT > "${layout_init}"
dashboard -output ${tty}

define hookpost-up
    dashboard
end

define hookpost-down
    dashboard
end

define hookpost-frame
    dashboard
end

LAYOUTINIT

  # define which windows to show in the dashboard
  layout="assembly breakpoints expressions history memory registers source stack threads variables"
  layout=( ${layout} ) # convert to array of windows names (delimits on whitespace)

  # write the dashboard layout configuration to our init script
  echo "dashboard -layout ${layout[@]}" >> "${layout_init}"

  # style attributes to apply to windows
  while read -re line; do
    # skip blank lines and comment lines
    [[ "${line}" =~ ^[[:space:]]*(#|$) ]] && continue
    # delimit fields of line by ":"
    attr=( $( strings.Split "${line}" ":" ) )
    # need both a window and attribute spec (2 fields minimum)
    [[ ${#attr[@]} -gt 1 ]] || continue
    # write dashboard style command to init file
    echo "dashboard ${attr[0]} -style ${attr[@]:1}" >> "${layout_init}"
  done < "${style}"

  # there are three init scripts we need to use:
  #   1. ${dashboard_init}: permanent/immutable Python extension, gdb-dashboard
  #   2. ${layout_init}: temporary script generated to configure gdb-dashboard
  #   3. ${gdbinit}: temporary script generated for the target device
  #
  # the second script (${layout_init}) is included/evaluated implicitly by
  # gdb-dashboard because of its path (~/.gdbinit.d).
  gdbcmd="$gdb_bin ${gdb_opt_init}${dashboard_init} ${gdb_opt_init}${gdbinit} ${gdb_args[@]}"
  echo "--------"
  echo ${gdbcmd}
  echo "--------"
  ${gdbcmd}

  tmux kill-pane -t "${id}"
  rm -f "${gdbinit}" "${layout_init}" # clean up, remove the init files
}

__openocd-gdbserver-command() {
  local cmd
  for (( i=1; i<=${#}; ++i )); do
    cmd="${cmd}${!i}"
    [[ ${i} -lt ${#} ]] &&
      cmd="${cmd};"
  done
  cat <<__CMD__ | tr '\n' ';'
    tcl_port disabled
    init
    reset init
    halt
    adapter speed 4000
__CMD__
    #telnet_port disabled
    #${cmd}
    #reset run
    #shutdown
}

openocd-gdbserver() {
	openocd_interface='interface/stlink.cfg'
	openocd_target='target/stm32h7x_dual_bank.cfg' # Arduino Portenta H7

	if ! "${openocd_bin}" \
	  -s "${openocd_src}" \
	  -f "${openocd_interface}" \
	  -f "${openocd_target}" \
  	-c "transport select swd; $(openocd-command "${openocd_cmd_program}")"; then
	  erro "failed to start debugger"
  	return 1
	fi
}

#!/bin/bash

# ------------------------------------------------------------------------------
#
#  functions and environment variables for using the Segger J-Link GDB SWD 
#  debugger. the serial number can be found printed on top of the device.
#
#  developed on and for Ubuntu, the J-Link EDU Mini, and an array of Adafruit
#  microcontrollers based on ARM Cortex M0 and M4 (SAMD) chipsets. should
#  probably work with most older Arduino-compatible (AVR) targets such as 
#  ATmega328, ATtiny85, etc. -- but I certainly haven't tested most of them.
#
#  verify the paths and options below.
#
#  typical usage for Arduino devices is as follows:
#
#    1. compile the sketch from the Arduino IDE
#      a. **NOTE** some newer boards/chips (like all of Adafruit's M4 boards)
#         actually have a "Debug" switch in the Tools menu to enable gcc's
#         debug flags... make goddamn sure its enabled to avoid frustration.
#
#    2. be sure to source this environment script, and then run one of the gdb
#       scripts with 2 paramters: (a) the path to the compiled ELF executable,
#       and (b) the name of the target processor core.
#
#       the path can be determined automatically based on file last mod (MTIME) 
#       time and the default build path (defined with the arduino_build_* vars 
#       below) as well as the processor core, given a string pattern describing
#       the common name of the board.
#
#       for example, debugging the most recently built Arduino executable on an
#       Adafruit Grand Central M4 using the ncurses-vi-like cgdb:
#
#         $ . ~/.jlinkrc    # (be sure to source this environment script)
#         $ jlink-gdbserver grand                         # <=-[ in console 1 ]
#         $ jlink-cgdb `newest-arduino-build-elf` grand   # <=-[ in console 2 ]
#
# ------------------------------------------------------------------------------

# serial number for the attached J-Link device
serialno="801008055" # J-Link EDU Mini
serialno="261012690" # J-Link EDU 
jlink-serial()
{
  echo "${serialno}"
}

segger_path="/opt/SEGGER"
jlink_path="${segger_path}/JLink"

arduino_build_dir_path="/tmp"
arduino_build_dir_prefix="arduino_build_"
arduino_build_bin_suffix=".ino.elf"

commander_bin="JLinkExe"
gdbserver_bin="JLinkGDBServer"

jlinkcore_bin=$( which jlink-core-id )

gdb_bin=$( which gdb-multiarch ) 
cgdb_bin=$( which cgdb )

dashboard_init="${HOME}/.config/gosh/share/gdb-dashboard/dashboard.gdbinit"

gdb_opt_init="--init-command=" # after loading inferior
#gdb_opt_init="--command="      # before loading inferior

jlink-commander()
{
  iface="SWD"
  speed="auto"

  device=$( __jlink-target-device ${@} )
  if [[ -n $device ]]
  then
    pushd "$jlink_path" &> "/dev/null"
    "$commander_bin" -autoconnect 1 -if "$iface" -speed "$speed" USB "$serialno" -device "$device"
    popd &> "/dev/null"
  fi
}

jlink-gdbserver()
{
  iface="SWD"
  speed="auto"
  port="3333"
  swoport="2332"
  telnetport="2333"
  endian="little"
  select="USB=$serialno"

  device=$( __jlink-target-device ${@} )
  if [[ -n $device ]]
  then
    pushd "$jlink_path" &> "/dev/null"
		# NOTE: use -x/-xc script.gdb to execute a gdb script once, or if -xc each 
		#       time a client connects.
	"$gdbserver_bin" -nogui -nosinglerun -nosilent -noir -strict -swoport "$swoport" -select "$select" -telnetport "$telnetport" -endian "$endian" -speed "$speed" -port "$port" -vd -device "$device" -if "$iface" -halt -reportuseraction -excdbg 2
    popd &> "/dev/null"
  fi
}

jlink-gdbserver-monitor() {
	local session='jlink-gdbserver'
	if ! tmux has-session -t "${session}" 2>/dev/null; then
		if [[ ${#} -lt 2 ]]; then
			echo $'usage:\n\tjlink-gdbserver-monitor serial-port [serial-baud] target-device'
			return 1
		fi
		local default=( gosh -p tinygo -p segger )
		local serport="${1}"; shift
		local serbaud="115200"
		local serwait="1s"
		if [[ ${#} -gt 1 ]] && [[ "${1}" =~ ^[0-9]+$ ]]; then
			serbaud="${1}"; shift
		fi
		local monitor=( screen "${serport}" "${serbaud}" )

		local cmd="${default[@]}"
		local mon="${monitor[@]}"

		echo "tmux: creating two panes (session: ${session}) ->
 [0] jlink-gdbserver ${@}
 [1] ${mon}"

		tmux new-session -d -t "${session}" -s "${session}"
		tmux set-option -t "${session}" "default-command" "${cmd}"
		tmux new-window -t "${session}" -n "${session}"
		sleep 0.2
		# use send-keys so that the commands are run in a default shell and do not
		# close their pane when the command exits
		tmux send-keys -t "${session}:${session}" "jlink-gdbserver ${@}" Enter
		tmux split-window -l 1 -t "${session}"
		tmux send-keys -t "${session}:${session}" "${mon}" Enter
		# remove the first window that was created at session startup
		tmux kill-window -t "${session}:^"

		echo "       initializing serial terminal (${serwait}) ..."
		# give screen some time to initialize serial terminal before attaching, so
		# that there isn't competition for screen drawing priority
		sleep ${serwait}
	fi

	[ -n "${TMUX:-}" ] &&
		tmux -u2 switch-client -t "${session}" ||
		tmux -u2 attach-session -t "${session}"
}

__jlink-gdb-options()
{
  tcpport="3333"

  symbols=$1
  if [[ -f "$symbols" ]]
  then
    perl -le "print STDERR 'using symbols from file: $symbols'"
    shift
    device=$( __jlink-target-device ${@} )
    if [[ -n $device ]]
    then

      symdir=$( readlink -f "$symbols" )
      symdir=$( dirname "$symdir" )

      gdbinit=$( mktemp -q -p "$symdir" -t "$( basename $symbols ).XXXXX.gdbinit" )

      # configure the default gdbinit options
      cat <<GDB >> "$gdbinit"
target remote localhost:$tcpport
monitor device "$device"
monitor speed auto
set remote memory-write-packet-size 1024
set remote memory-write-packet-size fixed
GDB

			# add arduino toolchain source directories if they exist
			for sub in core libraries preproc sketch; do
				[[ -d "${symdir}/${sub}" ]] &&
					find "${symdir}/${sub}" -type d -print0 |
						xargs -0 -L 1 -I {} echo "dir \"{}\"" >> "${gdbinit}"
			done
			[[ -d "${symdir}/libraries" ]] &&
				echo "dir \"${symdir}/libraries\"" >> "${gdbinit}"

			delaysec=0.2

			if [[ -z ${NORESET} ]]; then
				# add commands to specify symbol file, load executable onto target, and
				# reset target to the end of gdbinit.
				cat <<GDB >> "$gdbinit"
file "${symbols}"
shell sleep ${delaysec}
monitor reset
shell sleep ${delaysec}
load
shell sleep ${delaysec}
monitor reset
shell sleep ${delaysec}
GDB
			else
				# if NORESET is defined, just specify symbol file and load executable
				# onto target. do not reset target.
				cat <<GDB >> "$gdbinit"
file "${symbols}"
shell sleep ${delaysec}
load
shell sleep ${delaysec}
GDB
			fi

			# if userinit is defined and refers to an existing file, append its 
			# content to gdbinit. the executable file HAS been loaded at this point,
			# so userinit can define breakpoints without "unknown symbol" errors.
			[[ -f "${userinit}" ]] && cat "${userinit}" >> "$gdbinit"

      echo $gdbinit
      return 0

    fi
  else
    perl -le "print STDERR 'error: no symbols file (.elf) provided'"
  fi
  return 1
}

jlink-gdb-dashboard()
{
	if [[ ${#} -lt 2 ]]; then
		echo $'usage:\n\tjlink-gdb-dashboard exe-file target-device [user-init]'
		echo
		echo $'user-init is the path to a gdbinit script containing gdb commands to'
		echo $'evaluate AFTER the symbol file(s) have been loaded/uploaded AND the'
		echo $'target has been reset. So these would effectively be the set of'
		echo $'initial commands you would otherwise have to run manually every time'
		echo $'you begin debugging a target.'
		echo
		echo $'The commands in user-init are therefore evaluated at the following'
		echo $'step (5) during initialization:'
		echo
		echo $'    1. The executable file is loaded into memory.'
		echo $'    2. The executable file is loaded onto the target.'
		echo $'    3. The target is reset.'
		echo $'    4. The target is halted.'
		echo $'    5. Evaluate commands in user-init.'
		echo
		echo $'The user-init script is intended to let the user to set non-standard'
		echo $'source directory search paths (gdb command "directory [path]"), set'
		echo $'common breakpoints (e.g., "break Reset_Handler"), configure the'
		echo $'dashboard module (or its container tmux session), and to define any'
		echo $'target/session-specific commands (gdb command "define [name]").'
		echo
		echo $'You can also define initialization commands by placing them in any'
		echo $'file under [~/.gdbinit.d]. However, these will be evaluated PRIOR to'
		echo $'loading the symbol file and are thus unable to refer to symbols in'
		echo $'the loaded executable.'
		echo
		return 1
	fi

	opt_args=( "${@:1:2}" )
	userinit=
  [[ $? -eq 0 ]] || return $?
  if [[ $# -gt 2 ]]; then
    shift # symbols
    shift # target
		if [[ -f "${1}" ]]; then
			userinit="${1}" # take userinit file if provided
			shift
		fi
		gdb_args=( "${@}" )
  fi
  gdbinit=$( __jlink-gdb-options "${opt_args[@]}" )

	# create another init script for configuring the dashboard in our current tmux
	# window TTY
	layout_init="${HOME}/.gdbinit.d/100-dashboard"

	local id="$( tmux split-pane -hPF  "#D" "tail -f /dev/null" )"
	tmux last-pane
	local tty="$( tmux display-message -p -t "$id" '#{pane_tty}' )"

	# ensure the path exists to directory of init scrips
	layout_init_path=$( dirname "${layout_init}" )
	[[ -d "${layout_init_path}" ]] || mkdir -p "${layout_init_path}"

	# use our current tmux TTY for dashboard init
	cat <<LAYOUTINIT > "${layout_init}"
define hookpost-up
    dashboard
end

define hookpost-down
    dashboard
end

define hookpost-frame
    dashboard
end

dashboard -layout source stack registers assembly !variables !breakpoints !expressions !history !memory !threads
dashboard -style dereference             True
dashboard -style compact_values          True
dashboard -style max_value_length        800
dashboard -style divider_label_skip      1
dashboard -style divider_label_margin    0
dashboard stack -style limit             1
dashboard stack -style arguments         True
dashboard stack -style locals            False
dashboard stack -style align             False
dashboard registers -style column-major  True
dashboard source -style tab-size         2
dashboard source -style height           34

dashboard -output ${tty}
LAYOUTINIT

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

jlink-gdb()
{
  gdbinit=$( __jlink-gdb-options ${@:1:2} )
  [[ $? -eq 0 ]] || return $?
  gdb_args=()
  if [[ $# -gt 2 ]]
  then
    shift # symbols
    shift # target
    while test $# -gt 0
    do
        gdb_args=( "${gdb_args[@]}" "$1" )
        shift
    done
  fi
  gdbcmd="$gdb_bin ${gdb_opt_init}${gdbinit} ${gdb_args[@]}"
  echo "--------"
  echo $gdbcmd
  echo "--------"
  $gdbcmd 
  rm -f "$gdbinit" # clean up, remove the init file
}

jlink-cgdb()
{
  gdbinit=$( __jlink-gdb-options $@ )
  [[ $? -eq 0 ]] || return $?
  gdbcmd="$cgdb_bin -d $gdb_bin -- ${gdb_opt_init}${gdbinit}"
  echo "--------"
  echo $gdbcmd
  echo "--------"
  $gdbcmd
  rm -f "$gdbinit" # clean up, remove the init file
}

newest-arduino-build-dir()
{
  # only looks at the build directories' MTIME
  command ls -td "${arduino_build_dir_path}/${arduino_build_dir_prefix}"* | head -1
}

newest-arduino-build-elf()
{
  # looks at all of the compiled ELFs' MTIMEs to determine which was actually
  # compiled most recently. 

  # -maxdepth 2 because the compiled ELF should always be in the root of one
  # of the build dirs, which are themselves 1 level below the find root.
  find "$arduino_build_dir_path" -maxdepth 2 -type f -iname "*"${arduino_build_bin_suffix} \
    -printf "%Ts\t%p\n" 2>"/dev/null" | sort -nr | cut -f2 | head -1
}

__jlink-target-device()
{
  pushd "$self_path" &> "/dev/null"
  if [[ $# -gt 0 ]]
  then
    token=${@}
  else
    read -re -a token -p "target device or CPU core: "
  fi
  
	if core=$( "${jlinkcore_bin}" ${token[@]} ); then
		echo "${core}"
	fi
  popd &> "/dev/null"
}


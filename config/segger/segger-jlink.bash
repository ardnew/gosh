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

gdb_bin=$( which gdb-multiarch ) 
gdb_bin_init="/home/andrew/Development/gdb/gdb-dashboard/.gdbinit"

cgdb_bin=$( which cgdb )
cgdb_bin_init=

gdb_opt_init="--init-command=" # after loading inferior
#gdb_opt_init="--command="      # before loading inferior

jlink-commander()
{
  iface="SWD"
  speed="4000"

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
  speed="4000"

  device=$( __jlink-target-device ${@} )
  if [[ -n $device ]]
  then
    pushd "$jlink_path" &> "/dev/null"
    "$gdbserver_bin" -if "$iface" -speed "$speed" -device "$device"
    popd &> "/dev/null"
  fi
}

__jlink-gdb-options()
{
  tcpport="2331"

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

      if [[ -n $initbase ]]
      then
        echo "source $initbase" > "$gdbinit"
      fi

      # configure the default gdbinit options
      cat <<GDB >> "$gdbinit"
target remote localhost:$tcpport
monitor device "$device"
monitor speed auto
GDB

      # add all of the project's included libraries' sources to the gdb search path
      find "${symdir}/"{"core","libraries","preproc","sketch"} -type d -print | \
        while read -re lib
        do
          echo "dir \"$lib\"" >> "$gdbinit"
        done
      echo "dir \"$symdir/libraries\"" >> "$gdbinit"

      # add finishing options for restarting the target to the end of the gdbinit
      cat <<GDB >> "$gdbinit"
file "$symbols"
load
monitor reset
GDB

      echo $gdbinit
      return 0

    fi
  else
    perl -le "print STDERR 'error: no symbols file (.elf) provided'"
  fi
  return 1
}

jlink-gdb()
{
  gdbinit=$( __jlink-gdb-options $@ )
  [[ $? -eq 0 ]] || return $?
  gdbcmd="$gdb_bin ${gdb_opt_init}${gdb_bin_init} ${gdb_opt_init}${gdbinit}"
  echo "--------"
  echo $gdbcmd
  echo "--------"
  echo "  NOTE: redirect gdb-dashboard output to separate terminal:"
  echo "    >>> dashboard -output /dev/pts/<TTY#>"
  echo "     other dashboard commands can be autorun by editing file:"
  echo "    $HOME/.gdbinit.d/10-andrew"
  echo "--------"
  $gdbcmd 
  rm -f "$gdbinit" # clean up, remove the init file
}

jlink-cgdb()
{
  gdbinit=$( __jlink-gdb-options $@ )
  [[ $? -eq 0 ]] || return $?
  gdbcmd="$cgdb_bin -d $gdb_bin -- ${gdb_opt_init}${cgdb_bin_init} ${gdb_opt_init}${gdbinit}"
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
  
  core=$( perl <( cat <<"PL"
# this script accepts as input the name of an MCU board and prints the name of
# its processor core. this translation is intended for use when configuring
# the J-Link debugger when you only know the common name of the board and not
# the arbitrary processor identity.

use strict;
use warnings;

my @MCU =
  (
    [ "ATmega328P",  qw| Metro Mini 328 | ],
    [ "ATSAMD21G18", qw| Circuit Playground Express | ],
    [ "ATSAMD21G18", qw| Hallowing M0 Express | ],
    [ "ATSAMD21E18", qw| Gemma M0 | ],
    [ "ATSAMD51J19", qw| Feather M4 Express | ],
    [ "ATSAMD51P20", qw| Grand Central M4 Express | ],
    [ "ATSAMD51J20", qw| PyPortal | ],
    [ "ATSAMD51G19", qw| ItsyBitsy M4 Express | ],
    [ "ATSAMD21E18", qw| Trinket M0 | ],
    [ "STM32F405RG", qw| Feather STM32F405 Express | ],
  );

sub combine { $_ = lc join "", @_; s/[\s\-_]*//g; quotemeta $_ }

if (0 == scalar @ARGV)
{
  printf STDERR "error: no target board provided$/";

  print STDERR "known targets:$/";
  for my $mcu (@MCU)
  {
    my $core  = shift @$mcu;
    printf STDERR "  %s (%s)$/", join(" ", @$mcu), $core;
  }

  exit -1;
}

my $input = combine @ARGV;
my @match;

for my $mcu (@MCU)
{
  my $core  = shift @$mcu;
  my $ident = combine @$mcu;

  push @match, [ $core, @$mcu ]
    if $ident =~ /$input/i or $core =~ /$input/i;
}

my $count = scalar @match;

if (1 == $count)
{
  my $core = shift @{$match[0]};
  printf STDERR "using %s (%s)$/", join(" ", @{$match[0]}), $core;
  print "$core$/";
}
else
{
  if ($count > 1)
  {
    for my $m (@match)
    {
      my $core = shift @{$m};
      printf STDERR "  %s (%s)$/", join(" ", @$m), $core;
    }
    print STDERR "too many matches$/";
  }
  else # count < 1
  {
    print STDERR "no match$/";
  }
  exit 1;
}
PL
  ) ${token[@]} )
  [[ $ret -eq 0 ]] && echo $core
  popd &> "/dev/null"
}


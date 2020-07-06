##!/bin/bash

escape() # escape bash metachars
{
  local args="$@"
  printf "$args" | sed -e "s/'/'\\\\''/g; 1s/^/'/; \$s/\$/'/"
}

manbuiltin() # easy access to bash built-ins
{
  man bash | less -p "^ {4,7}$1 "
  #help $1 # another potential doc source
}

useshopt()
{
  local isset=$( shopt "${1}" > /dev/null ; printf $? )
  shopt -s "${1}" ; "${@:2}"
  [[ 1 == "${isset}" ]] && shopt -u "${1}"
}

ignorecase()
{
  useshopt "nocasematch" "$@"
}

arrjoin()
{
  local IFS="$1"
  shift
  echo ${@}
}

dos2unix()
{
  if type -P dos2unix > /dev/null
  then
    command dos2unix "$@"
  else
    perl -pi -e 's/\r\n|\n|\r/\n/g' "$@"
  fi
}

unix2dos()
{
  if type -P unix2dos > /dev/null
  then
    command unix2dos "$@"
  else
    perl -pi -e 's/\r\n|\n|\r/\r\n/g' "$@"
  fi
}

unixtime2date()
{
  if [[ $# -gt 0 ]]
  then
    local seconds=${1}
    if [[ $seconds -gt 86400 ]] # seconds in a day
    then
      printf "%d days " $(( seconds / 86400 ))
    fi
    date -d "1970-01-01 + $seconds seconds" "+%H hrs %M min %S sec"

  fi
}

rgb2hex()
{
  perl -le 'printf"0x%02X%02X%02X$/",map{($_<=1.0&&$_>=0.0) ? int($_*255+0.5) : $_}@ARGV' $@
}

hex2rgb()
{
  perl -le '@_=map{oct("0x$_")/0xFF}(shift=~/../g);print"@_[@_-3..$#_]"' $@
}

enum-colors()
{
  (
    x=`tput op` y=`printf %76s`
    for i in {0..256}
    do
      o=00$i
      echo -e ${o:${#o}-3:3} `tput setaf $i;tput setab $i`${y// /=}$x
    done
  )
}

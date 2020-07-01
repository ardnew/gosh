##!/bin/bash
#
## ==============================================================================
##
##  file: functions.bash
##
##  date: 19 June 2020
##
##  auth: andrew@ardnew.com
##
##  desc: shell function definitions
##
## ==============================================================================
#escape()
#{
#  local args="$@"
#  printf "$args" | sed -e "s/'/'\\\\''/g; 1s/^/'/; \$s/\$/'/"
#}
#
#manbuiltin() # easy access to bash built-ins
#{
#  man bash | less -p "^ {4,7}$1 "
#  #help $1 # another potential doc source
#}
#
#useshopt()
#{
#  local isset=$( shopt "${1}" > /dev/null ; printf $? )
#  shopt -s "${1}" ; "${@:2}"
#  [[ 1 == "${isset}" ]] && shopt -u "${1}"
#}
#
#ignorecase()
#{
#  useshopt "nocasematch" "$@"
#}
#
#uc()
#{
#  if [[ $# -gt 0 ]]
#  then
#    tr '[:lower:]' '[:upper:]' <<<"$@"
#  fi
#}
#
#lc()
#{
#  if [[ $# -gt 0 ]]
#  then
#    tr '[:upper:]' '[:lower:]' <<<"$@"
#  fi
#}
#
#nullglob()
#{
#  useshopt "nullglob" "$@"
#}
#
#arrjoin()
#{
#  local IFS="$1"
#  shift
#  echo ${@}
#}
#
#maxlen()
#{
#  local wide=0
#  for e in "${@}"
#  do
#    len=${#e}
#    wide=$(( len > wide ? len : wide ))
#  done
#  echo ${wide}
#}
#
#streq()
#{
#  if [[ ${#1} -eq ${#2} ]] && [[ $1 == $2 ]] ; then
#    echo $TRUE ;
#  else
#    echo $FALSE ;
#  fi
#}
#
#streqi()
#{
#  ignorecase streq "$@"
#}
#
#fout()
#{
#  [[ $# -gt 0 ]] && "$@" 2>&1
#}
#
#ferr()
#{
#  [[ $# -gt 0 ]] && "$@" 1>&2
#}
#
#silent()
#{
#  [[ $# -gt 0 ]] && "$@" &> /dev/null
#}
#
#silentout()
#{
#  [[ $# -gt 0 ]] && "$@" 1> /dev/null
#}
#
#silenterr()
#{
#  [[ $# -gt 0 ]] && "$@" 2> /dev/null
#}
#
#rmtrailing()
#{
#  if [[ ${#} -gt 1 ]]
#  then
#    shopt -s extglob
#    echo "${1%%+(${2})}"
#  fi
#}
#
#rmtrailingslashes()
#{
#  if [[ ${#} -gt 0 ]]
#  then
#    rmtrailing "${1}" '/'
#  fi
#}
#
#dos2unix()
#{
#  if type -P dos2unix > /dev/null
#  then
#    command dos2unix "$@"
#  else
#    perl -pi -e 's/\r\n|\n|\r/\n/g' "$@"
#  fi
#}
#
#unix2dos()
#{
#  if type -P unix2dos > /dev/null
#  then
#    command unix2dos "$@"
#  else
#    perl -pi -e 's/\r\n|\n|\r/\r\n/g' "$@"
#  fi
#}
#
#
#now_long()
#{
#  date +"${datetime_format}"
#}
#
#now()
#{
#  date +"${datetime_file_format}"
#}
#
#readablesec()
#{
#  if [[ $# -gt 0 ]]
#  then
#    local seconds=${1}
#    if [[ $seconds -gt 86400 ]] # seconds in a day
#    then
#      printf "%d days " $(( seconds / 86400 ))
#    fi
#    date -d "1970-01-01 + $seconds seconds" "+%H hrs %M min %S sec"
#
#  fi
#}
#
#tgzbackup()
#{
#  if [[ ${#} -gt 0 ]]
#  then
#    if [[ -d ${1} ]]
#    then
#      local src=`rmtrailingslashes "${1}"`
#      local dst="${src}__`now`.tgz"
#      echo "[+] compressing \"${1}\" to \"${dst}\""
#      tar -czvf "${dst}" "${src}"
#    else
#      echo "error: input must be a directory"
#    fi
#  fi
#}
#
#tbzbackup()
#{
#  if [[ ${#} -gt 0 ]]
#  then
#    if [[ -d ${1} ]]
#    then
#      local src=`rmtrailingslashes "${1}"`
#      local dst="${src}__`now`.tbz"
#      echo "[+] compressing \"${1}\" to \"${dst}\""
#      tar -cjvf "${dst}" "${src}"
#    else
#      echo "error: input must be a directory"
#    fi
#  fi
#}
#
#zipbackup()
#{
#  if [[ ${#} -gt 0 ]]
#  then
#    if [[ -d ${1} ]]
#    then
#      local src=`rmtrailingslashes "${1}"`
#      local dst="${src}__`now`.zip"
#      echo "[+] compressing \"${src}\" to \"${dst}\""
#      zip -r "${dst}" "${src}"
#    else
#      echo "error: input must be a directory"
#    fi
#  fi
#}
#
#backup()
#{
#  if [[ ${#} -gt 0 ]]
#  then
#    local src=`rmtrailingslashes "${1}"`
#    local dst="${src}__`now`"
#    echo "[+] copying \"${1}\" to \"${dst}\""
#    cp -r "${src}" "${dst}"
#  fi
#}
#
#stamp()
#{
#  if [[ $# -gt 0 ]]
#  then
#    local src=`rmtrailingslashes "${1}"`
#    local dst="${src}__`now`"
#    mv "${src}" "${dst}"
#    echo "${dst}"
#  fi
#}
#
#stamp_unixtime()
#{
#  if [[ $# -gt 0 ]]
#  then
#    local src=`rmtrailingslashes "${1}"`
#    local dst="${src}".`date "+%s"`
#    mv "${src}" "${dst}"
#    echo "${dst}"
#  fi
#}
#
#quiet_nohup()
#{
#  if [[ $# = 0 || -z $@ ]]
#  then
#    echo "error: quiet_nohup: no command"
#  else
#    nohup "$@" > /dev/null 2>&1 &
#  fi
#}
#
#abspath()
#{
#  # bash doesn't have a truly portable+reliable means
#  perl -MCwd=abs_path -MFile::Spec=rel2abs,canonpath \
#    -e 'print abs_path($_=(shift)||".") || File::Spec->canonpath(File::Spec->rel2abs($_))' "${1}"
#}
#
#iscmd()
#{
#  [[ $# -gt 0 ]] && silent type -t "${1}" && echo 1
#}
#
#rgb2hex()
#{
#  perl -le 'printf"0x%02X%02X%02X$/",map{($_<=1.0&&$_>=0.0) ? int($_*255+0.5) : $_}@ARGV' $@
#}
#
#hex2rgb()
#{
#  perl -le '@_=map{oct("0x$_")/0xFF}(shift=~/../g);print"@_[@_-3..$#_]"' $@
#}
#
#enum-colors()
#{
#  (
#    x=`tput op` y=`printf %76s`
#    for i in {0..256}
#    do
#      o=00$i
#      echo -e ${o:${#o}-3:3} `tput setaf $i;tput setab $i`${y// /=}$x
#    done
#  )
#}

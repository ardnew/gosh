#!/bin/bash

case "${host_kind}" in
  $host_linux)
	global_bash_completion="/usr/local/src/bash-completion/bash_completion"
	;;
  $host_darwin)
	global_bash_completion="/usr/local/src/bash-completion/bash_completion"
	;;
  $host_cygwin)
	;;
  $host_mswsl)
	;;
  *)
	# source the completion scripts pre-installed on the system
	global_bash_completion="/usr/share/bash-completion/bash_completion"
	;;
esac

system_bash_completion="/etc/bash_completion"
if ! shopt -oq posix; then
	if [ -f "${global_bash_completion}" ]; then
		. "${global_bash_completion}"
	elif [ -f "${system_bash_completion}" ]; then
		. "${system_bash_completion}"
	fi
fi

# basic Makefile completion
#complete -W "$([[ -f Makefile ]] && "                          \
#	"command grep -oE '^[a-zA-Z0-9_.-]+:([^=]|$)' Makefile | " \
#	"sed 's/[^a-zA-Z0-9_.-]*$//')" make

_mkcache() {
    local _file="$1"
    # add "-r" to omit defaults (60+ rules)
    ${MAKE:-make} ${_file:+-f "$_file"} -qp 2>/dev/null |
    gawk '/^# *Make data base/,/^# *Finished Make data base/{
      if (/^# Not a target/) { getline; next }
      ## handle "target: ..."
      if (match($0,/^([^.#% ][^:%=]+) *:($|[^=])(.*)/,bits)) {
          #if (bits[3]=="") next # OPT: skip phony
          printf("%s\n",bits[1])
      }
      ## handle "%.x [...]: %.y [| x]", split into distinct targets/prereqs
      else if (match($0,/^([^:]*%[^:]*) *(::?) *(.*%.*) *(\| *(.*))?/,bits)) {
          #if (bits[3]=="%") next # OPT: skip wildcard ones
          nb1=split(bits[1],bb1)
          nb3=split(bits[3],bb3)
          for (nn=1; nn<=nb1; nn++) 
            for (mm=1; mm<=nb3; mm++) 
              printf("%s : %s\n",bb1[nn],bb3[mm])
      }
      ## handle fixed (no %) deps
      else if (match($0,/^([^:]*%[^:]*) *(::?) *([^%]*)$/,bits)) {
          if (bits[3]=="") next # phony
          printf("%s : %s\n",bits[1],bits[3])
      }
      ## handle old form ".c.o:"  rewrite to new form "%.o: %.c"
      else if (match($0,/^\.([^.]+)\.([^.]+): *(.*)/,bits)) {
          printf("%%.%s : %%.%s\n", bits[2],bits[1])
      }
    }' > ".${_file:-Makefile}.targets"
}

_bc_make() {
    local ctok=${COMP_WORDS[COMP_CWORD]}   # curr token
    local ptok=${COMP_WORDS[COMP_CWORD-1]} # prev token
    local -a mkrule maybe
    local try rr lhs rhs rdir pat

		# give priority to any Makefile path in env
		local makefile=${MAKEFILE}
		# fallback on some default Makefile file names
		[[ -f "${makefile}" ]] || makefile='Makefile'
		[[ -f "${makefile}" ]] || makefile='makefile'
		if [[ ! -f "${makefile}" ]]; then
			# check if -f flag exists in current command line
			for (( i = 0; i < ${#COMP_WORDS[@]}-1; ++i )); do
				if [[ '-f' == ${COMP_WORDS[${i}]} ]]; then
					# found -f flag. use its argument as Makefile
					makefile="${COMP_WORDS[$(( i+1 ))]}"
					break
				fi
			done
		fi

		# bail out unless we have found a Makefile
		if [[ ! -f "${makefile}" ]]; then
			COMPREPLY=()
			return
		fi

    ## check we're not doing any make options 
    [[ ${ctok:0:1} != "-" && ! $ptok =~ ^-[fCIjloW] ]] && {
        COMPREPLY=()
        [[ "$makefile" -nt .${makefile}.targets ]] && 
            _mkcache "$makefile"

        mapfile -t mkrule < ".${makefile}.targets"
        # mkrule+=( "%.o : %.c" )  # stuff in extra rules

        for rr in "${mkrule[@]}"; do
            IFS=": " read lhs rhs <<< $rr

            ## special "archive(member):"
            [[ "$lhs" =~ ^(.*)?\((.+)\) ]] && {
                continue # not handled
            }

            ## handle simple targets
            [[ "$rhs" == "" ]] && {
                COMPREPLY+=( $(compgen -W "$lhs" -- "$ctok" ) )
                continue
            }

            ## rules with a path, like "% : RCS/%,v" 
            rdir=""
            [[ "$rhs" == */* ]] && rdir="${rhs/%\/*/}/" 
            rhs=${rhs/#*\//}

            ## expand (glob) that matches RHS 
            ## if current token already ends in a "." strip it
            ## match by replacing "%" stem with "*"

            [[ $ctok == *. ]] && try="${rdir}${rhs/\%./$ctok*}" \
                              || try="${rdir}${rhs/\%/$ctok*}"

            maybe=( $(compgen -G "$try") )  # try must be quoted

            ## maybe[] is an array of filenames from expanded prereq globs
            (( ${#maybe[*]} )) && {

               [[ "$rhs" =~ % ]] && {
                   ## promote rhs glob to a regex: % -> (.*)
                   rhs="${rhs/./\\.}"
                   pat="${rdir}${rhs/\%/(.*)}"

                   ## use regex to extract stem from RHS, sub "%" on LHS
                   for nn in "${maybe[@]}"; do 
                       [[ $nn =~ $pat ]] && {
                           COMPREPLY+=( "${lhs/\%/${BASH_REMATCH[1]}}" )
                       }
                   done
               } || {
                   # fixed prereqs (no % on RHS)
                   COMPREPLY+=( "${lhs/\%/$ctok}" )   
               }
            }
        done
        return
    }
    COMPREPLY=() #default
}
complete -F _bc_make ${MAKE:-make}

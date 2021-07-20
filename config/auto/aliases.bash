#!/bin/bash

# print commands as they are executed, and exit if it returns non-zero
alias trap-trace='trap "set +exET ; trap - ERR RETURN" ERR RETURN ; set -exET'

# ls
alias     l="command ls"
alias    ls="l -C -F --color=always"
alias    ll="ls -l -s -h --group-directories-first"
alias    la="ll -a"
alias    lm="ll -A"

# exa
if type -P exa &> /dev/null; then
	alias   e="command exa --icons --group-directories-first"
	alias  ll="e --long --time=modified --group --binary --links --git --octal-permissions"
	alias  lz="ll --sort=size"
	alias  lt="ll --sort=newest"
	alias  lr="ll --tree"
fi

# grep
alias    g="command grep"
alias grep="g --color=always --perl-regexp -I"

# cat
if type -P bat &> /dev/null; then
	alias cat='bat --paging=never --plain'
fi

# show whitespace symbols
alias white='tr " " "." | sed -E "s/\t/ -> /g"' # space='.', tab=' -> '
alias whiteln='white | sed -E "s/$/$/"'         # eol='$'

# base conversions
alias d2h="perl -e 'printf qq|%X$/|, int(shift)'"
alias d2o="perl -e 'printf qq|%o$/|, int(shift)'"
alias d2b="perl -e 'printf qq|%b$/|, int(shift)'"
alias h2d="perl -e 'printf qq|%d$/|, hex(shift)'"
alias h2o="perl -e 'printf qq|%o$/|, hex(shift)'"
alias h2b="perl -e 'printf qq|%b$/|, hex(shift)'"
alias o2h="perl -e 'printf qq|%X$/|, oct(shift)'"
alias o2d="perl -e 'printf qq|%d$/|, oct(shift)'"
alias o2b="perl -e 'printf qq|%b$/|, oct(shift)'"

# xxd
alias bytes='xxd -c1'
alias  bits='xxd -c1 -b'

# cgdb
alias cgdb='command cgdb -d gdb-multiarch -- -q'

# subversion
alias  sci='svn commit'
alias  srm='svn rm'
alias  sup='svn update'
alias surl='svn info | command grep -oP "^(URL|Revision):\s*\K.*" | tr "\n" "@" | sed -E "s/@+$/\n/"'

# apt
alias apt-search='apt-cache search --names-only'

# file utils
alias find.dos="command grep -IUlr $'\r'"

# locate
alias locate-re="locate --regex"

# tree
if type -P tree &> /dev/null; then
	alias         t='command tree'
	alias      tree='t -A -C -F --dirsfirst'
	alias    l.tree='tree -i -f'
	alias   ll.tree='l.tree -p -u -g -s -D'
	alias   la.tree='ll.tree -a'
	alias   ld.tree='ll.tree -d'
	alias du-b.tree='tree -s --du'
	alias du-s.tree='du-b.tree --sort=size'
	alias du-h.tree='tree -h --du'
fi

# terminal
if type -p tput &> /dev/null; then
	alias lastcol='echo $(( $( tput cols ) - 1 ))'
fi

# Xresources
alias reload-xresources='xrdb -merge ${HOME}/.Xresources'

# diff
alias diff='diff --report-identical-files --suppress-blank-empty --new-file --no-ignore-file-name-case --minimal --speed-large-files --color=always'
alias diff.unified='diff --unified'
alias diff.cfunc='diff --show-c-function'
if type -p tput &> /dev/null; then
	alias diff.split='diff --side-by-side --width=$( lastcol )'
fi

# BeyondCompare
if type -p bcompare &> /dev/null; then
	alias bdiff='bcompare'
fi

# feh
alias feh.thumbs='feh -t -E 128 -y 128 -W 1024'

if type -p mark-my-words &> /dev/null; then
	alias md='mark-my-words'
fi

# utility
alias groups-reload='exec sudo su -l $USER'
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

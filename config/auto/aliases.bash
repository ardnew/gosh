#!/bin/bash

# ls
alias     l="command ls"
alias    ls="l -C -F --color=always"
alias    ll="ls -l -s -h --group-directories-first"
alias    la="ll -a"
alias    lm="ll -A"

# grep
alias    g="command grep"
alias grep="g --color=always --perl-regexp -I"

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

# BeyondCompare
if type -p bcompare &> /dev/null; then
	alias bdiff='bcompare'
fi

# utility
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

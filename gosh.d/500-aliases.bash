#!/bin/bash

# ==============================================================================
#
#  file: aliases.bash
#
#  date: 19 June 2020
#
#  auth: andrew@ardnew.com
#
#  desc: shell alias definitions
#
# ==============================================================================

# shell commands
lsopt_def="lsh --group-directories-first"
lsopt_ext="a${lsopt_def}"
lsopt_all="A${lsopt_def}"

alias    ls='ls --color=auto'
alias     l='ls -CF'
alias    ll="l -${lsopt_def}"
alias    la="l -${lsopt_all}"
alias   lla="l -${lsopt_ext}"
alias   llc='ll --color=always'
alias cgrep="grep --color=always"

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

# subversion
alias  sci='svn commit'
alias  srm='svn rm'
alias  sup='svn update'
alias surl='svn info | command grep -oP "^(URL|Revision):\s*\K.*" | tr "\n" "@" | sed -E "s/@+$/\n/"'

# apt
alias apt-search='apt-cache search --names-only'

# systemd
alias systemctl='systemctl --no-pager'
alias       sdc='systemctl'

#  rsync
alias cpstruct='rsync -avhu --progress -f"+ */" -f"- *"'
alias syncdirs='rsync -avhu --progress'
alias     rscp='rsync -rave ssh --progress'

# file utils
alias finddos="grep -IUlr $'\r'"

# tree
if type -P tree &> /dev/null; then
  alias    l.tree='tree -ifDAC --dirsfirst'
  alias   ll.tree='tree -ifpugsDAC --dirsfirst'
  alias  lla.tree='tree -aifpugsDAC --dirsfirst'
  alias  lld.tree='tree -difpugsDAC --dirsfirst'
  alias du-s.tree='tree -ifsDAC --dirsfirst'
  alias du-h.tree='tree -ifhDAC --dirsfirst'
fi

# tmux
alias tmux="TERM=screen-256color /usr/bin/tmux $@"

# utility
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

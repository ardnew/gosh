#!/bin/bash
# indicate our inclusion to all who follow
__gosh_prompt="prompt.bash"
__gosh_prompt_includes=$( basename "${__gosh_prompt}" ".bash" )".d"

# source all files in the includes directory
if [[ -d "${__gosh_prompt_includes}" ]]; then
	for inc in "${__gosh_prompt_includes}"/*; do
		. "${inc}"
	done
fi

__prompt_command() {
	#sym=( "❯" "»" "᚛" "›" "≔" "≫" "⊳" "⋙" "⟫" "⟢" "⟣" "⟤" "⟥" "⦊" "⦒" "⧁" "⧉" "⧐" "⧴" "⨠" "⩴" "⪢" "⫎" "⫸" "『" "「" "｢" "⸢" "⸤" "⸂" "⸄" "⫭" "⧨" "⧂" "⦧" "⟌" "⌈" "⌊" )

	local exit_code=${?}

	local user_name_color='\[\e[0;38;5;45m\]'
	local user_name='\u'
	local user="${user_name_color}${user_name}"

	local at_sign_color='\[\e[0;38;5;195m\]'
	local at_sign='@'
	local at="${at_sign_color}${at_sign}"

	local host_name_color='\[\e[0;38;5;159m\]'
	local host_name='\h'
	local host="${host_name_color}${host_name}"

	local dir_curr_color='\[\e[0;38;5;39m\]'
	local dir_curr='\w'
	local dir="${dir_curr_color}${dir_curr}"

	export GIT_PS1_SHOWDIRTYSTATE=1
	local git_branch_color='\[\e[0;38;5;154m\]'
	local git_branch="$(__git_ps1)"
	local git="${git_branch_color}${git_branch}"

	local prompt_sym_color='\[\e[0;38;5;195m\]'
	[[ ${exit_code} -ne 0 ]] && \
		prompt_sym_color='\[\e[0;38;5;196m\]'
	local prompt_sym=' ⧉ '
	local prompt="${prompt_sym_color}${prompt_sym}"

	local end='\[\e0'"\[$(tput sgr0)\] "

	PS1="${user}${at}${host} ${dir}${git}\n${prompt}${end}"
}
export PROMPT_COMMAND=__prompt_command

##	# set variable identifying the chroot you work in (used in the prompt below)
##	if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
##		debian_chroot=$(cat /etc/debian_chroot)
##	fi
##
##	# set a fancy prompt (non-color, unless we know we "want" color)
##	case "$TERM" in
##		xterm-color|*-256color) color_prompt=yes;;
##	esac
##
##	# uncomment for a colored prompt, if the terminal has the capability; turned
##	# off by default to not distract the user: the focus in a terminal window
##	# should be on the output of commands, not on the prompt
##	#force_color_prompt=yes
##
##	if [ -n "$force_color_prompt" ]; then
##		if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
##			# We have color support; assume it's compliant with Ecma-48
##			# (ISO/IEC-6429). (Lack of such support is extremely rare, and such
##			# a case would tend to support setf rather than setaf.)
##			color_prompt=yes
##		else
##			color_prompt=
##		fi
##	fi
##
##	if [ "$color_prompt" = yes ]; then
##		PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
##	else
##		PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
##	fi
##	unset color_prompt force_color_prompt
##
##	# If this is an xterm set the title to user@host:dir
##	case "$TERM" in
##	xterm*|rxvt*)
##		PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
##		;;
##	*)
##		;;
##	esac

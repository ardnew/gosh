#!/bin/bash

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
	[[ ${exit_code} -ne 0 ]] && prompt_sym_color='\[\e[0;38;5;196m\]'
	local prompt_sym=' ⧨ '
	#local prompt_sym=' ⪢ '
	#local prompt_sym=' ⧉ '
	local prompt="${prompt_sym_color}${prompt_sym}"

	local end='\[\e0'"\[$(tput sgr0)\] "

	PS1="${user}${at}${host} ${dir}${git}\n${prompt}${end}"
}
export PROMPT_COMMAND=__prompt_command

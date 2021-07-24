_task_completion()
{
  local scripts curr

  # Remove colon from word breaks
  COMP_WORDBREAKS=${COMP_WORDBREAKS//:}

  scripts=$(task -l -s)
	options=$(task -h 2>&1 | command grep -oP '^\s+(-\w, )?\K--\S+')

  curr="${COMP_WORDS[COMP_CWORD]}"

  # Do not accept more than 1 argument
  if [ "${#COMP_WORDS[@]}" != "2" ]; then
    return
  fi

  if [[ "${curr}" =~ ^- ]] || [[ "${scripts}" == "" ]]; then
    COMPREPLY=($(compgen -W "${options}" -- ${curr}))
  elif [[ "${scripts}" != "" ]]; then
    COMPREPLY=($(compgen -W "${scripts}" -- ${curr}))
  fi
}

complete -F _task_completion -o default task

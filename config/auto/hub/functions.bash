#!/bin/bash

git-new-repo() {

	repo=$( basename "${PWD}" )

	[[ -f "README.md" ]] || printf "# %s\n" "${repo}" > "README.md"

	local create_opts

	if [[ $# -gt 0 ]]; then
		printf "### %s\n" "${1}" >> "README.md"
		create_opts=( -d "${1}" )
	fi

	if hub init && hub create -c "${create_opts[@]}"; then
		git add "README.md"
		git commit -m "Initial commit"
		git push --set-upstream origin master
	fi
}

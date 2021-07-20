#!/bin/bash

mkpdf2textproc() {
	echo '#!/bin/bash

# Intended for use as a ripgrep preprocessor as follows:
#
#   $ rg --pre path/to/this.sh [...]
#
# You may want to use --pre-glob to limit when this gets invoked, otherwise it
# will simply `cat` the given file paths:
#
#   $ rg --pre path/to/this.sh --pre-glob '*.pdf' [...]

case "${1}" in
	*.pdf) exec pdftotext "${1}" - ;;
	*)     exec cat "${1}" ;;
esac
'
}

grep-pdf() {
	if rg=$( type -P rg ); then
		if pt=$( type -P pdf2text.rg.sh ); then
			"${rg}" --engine pcre2 --pre "${pt}" "${@}"
		else
			erro "error: PDF-to-text preprocessor not found: pdf2text.rg.sh (create with: mkpdf2textproc)"
			return 1
		fi
	else
		erro "error: ripgrep not found: rg"
		return 1
	fi
}


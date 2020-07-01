This directory contains (at the root level) the files to be sourced for a bash 
shell session.

The order in which files are sourced is specified by their filename, with the
names formatted according to the following convention (ASCII-only):

| Pattern       | Description                                                            |
|:--------------|:-----------------------------------------------------------------------|
|`^\s*`         |  beginning of string (0 or more whitespace)                            |
|`\d+`          |  1 or more digits                                                      |
|`[\-\._ ]`     |  1 hyphen, period, underscore, or space                                | 
|`\S+`          |  any string of 1 or more non-whitespace characters                     |
|`[\-\._]env`   |  string "env" (with 1 leading hyphen, period, or underscore)           |
|`(\.(ba)?sh)?` |  (OPTIONAL) ".bash" or ".sh" (with leading period)                     |
|`(\.?rc)?`     |  (OPTIONAL) "rc" or ".rc"                                              |
|`\s*$`         |  end of string (0 or more whitespace)                                  |

Combined, in its entirety:

`^\s*\d+[\-\._ ]\S+[\-\._]env(\.(ba)?sh)?(\.?rc)?\s*$`

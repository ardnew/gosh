#!/bin/bash

go_completion="${GOPATH}/bin/gocomplete"
[[ -f "${go_completion}" ]] && complete -C "${go_completion}" go

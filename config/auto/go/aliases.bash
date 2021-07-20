#!/bin/bash

if type -p colorgo &> /dev/null; then
	alias go='colorgo'
fi

if type -p richgo &> /dev/null; then
	alias gotest='richgo test'
	alias gotest.color='RICHGO_FORCE_COLOR=1 richgo test'
fi

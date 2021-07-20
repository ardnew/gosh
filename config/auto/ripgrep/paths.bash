#!/bin/bash

path_rg_config=$( goshconfig -d )/share/ripgrep/config

[[ -f "${path_rg_config}" ]] && export RIPGREP_CONFIG_PATH=${path_rg_config}


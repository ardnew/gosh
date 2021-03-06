#!/bin/bash

mutt_mail="/var/mail/${USER}"

[[ -f "${mutt_mail}" ]] && MAIL="${mutt_mail}"

export MAIL

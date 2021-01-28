#!/bin/bash

mutt_email="andrew@ardnew.com"
mutt_mail="/var/mail/andrew"

[[ -f "${mutt_mail}" ]] && MAIL="${mutt_mail}"

export EMAIL="${mutt_email}" MAIL

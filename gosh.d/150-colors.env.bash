#!/bin/bash

# ==============================================================================
#
#  file: colors.bash
#
#  date: 19 June 2020
#
#  auth: andrew@ardnew.com
#
#  desc: convenient named colors
#
# ==============================================================================

uncolorseq()
{
  echo "${@}" | sed -r 's/\\\[\\e\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]\\\]//g'
}

# Reset
NoColor='\e[0m'       # Text Reset

FGBlue='\033[38;5;33m'

# Regular Colors
Black='\e[0;30m'        # Black
Red='\e[0;31m'          # Red
Green='\e[0;32m'        # Green
Yellow='\e[0;33m'       # Yellow
Blue='\e[0;34m'         # Blue
Purple='\e[0;35m'       # Purple
Cyan='\e[0;36m'         # Cyan
White='\e[0;37m'        # White

# Bold
BBlack='\e[1;30m'       # Black
BRed='\e[1;31m'         # Red
BGreen='\e[1;32m'       # Green
BYellow='\e[1;33m'      # Yellow
BBlue='\e[1;34m'        # Blue
BPurple='\e[1;35m'      # Purple
BCyan='\e[1;36m'        # Cyan
BWhite='\e[1;37m'       # White

# Underline
UBlack='\e[4;30m'       # Black
URed='\e[4;31m'         # Red
UGreen='\e[4;32m'       # Green
UYellow='\e[4;33m'      # Yellow
UBlue='\e[4;34m'        # Blue
UPurple='\e[4;35m'      # Purple
UCyan='\e[4;36m'        # Cyan
UWhite='\e[4;37m'       # White

# Background
On_Black='\e[40m'       # Black
On_Red='\e[41m'         # Red
On_Green='\e[42m'       # Green
On_Yellow='\e[43m'      # Yellow
On_Blue='\e[44m'        # Blue
On_Purple='\e[45m'      # Purple
On_Cyan='\e[46m'        # Cyan
On_White='\e[47m'       # White

# High Intensity
IBlack='\e[0;90m'       # Black
IRed='\e[0;91m'         # Red
IGreen='\e[0;92m'       # Green
IYellow='\e[0;93m'      # Yellow
IBlue='\e[0;94m'        # Blue
IPurple='\e[0;95m'      # Purple
ICyan='\e[0;96m'        # Cyan
IWhite='\e[0;97m'       # White

# Bold High Intensity
BIBlack='\e[1;90m'      # Black
BIRed='\e[1;91m'        # Red
BIGreen='\e[1;92m'      # Green
BIYellow='\e[1;93m'     # Yellow
BIBlue='\e[1;94m'       # Blue
BIPurple='\e[1;95m'     # Purple
BICyan='\e[1;96m'       # Cyan
BIWhite='\e[1;97m'      # White

# High Intensity backgrounds
On_IBlack='\e[0;100m'   # Black
On_IRed='\e[0;101m'     # Red
On_IGreen='\e[0;102m'   # Green
On_IYellow='\e[0;103m'  # Yellow
On_IBlue='\e[0;104m'    # Blue
On_IPurple='\e[10;95m'  # Purple
On_ICyan='\e[0;106m'    # Cyan
On_IWhite='\e[0;107m'   # White

show_colors()
{
# Regular Colors
  printf "${Black} Black ${NoColor}\n"
  printf "${Red} Red ${NoColor}\n"
  printf "${Green} Green ${NoColor}\n"
  printf "${Yellow} Yellow ${NoColor}\n"
  printf "${Blue} Blue ${NoColor}\n"
  printf "${Purple} Purple ${NoColor}\n"
  printf "${Cyan} Cyan ${NoColor}\n"
  printf "${White} White ${NoColor}\n"

# Bold
  printf "${BBlack} BBlack ${NoColor}\n"
  printf "${BRed} BRed ${NoColor}\n"
  printf "${BGreen} BGreen ${NoColor}\n"
  printf "${BYellow} BYellow ${NoColor}\n"
  printf "${BBlue} BBlue ${NoColor}\n"
  printf "${BPurple} BPurple ${NoColor}\n"
  printf "${BCyan} BCyan ${NoColor}\n"
  printf "${BWhite} BWhite ${NoColor}\n"

# Underline
  printf "${UBlack} UBlack ${NoColor}\n"
  printf "${URed} URed ${NoColor}\n"
  printf "${UGreen} UGreen ${NoColor}\n"
  printf "${UYellow} UYellow ${NoColor}\n"
  printf "${UBlue} UBlue ${NoColor}\n"
  printf "${UPurple} UPurple ${NoColor}\n"
  printf "${UCyan} UCyan ${NoColor}\n"
  printf "${UWhite} UWhite ${NoColor}\n"

# Background
  printf "${On_Black} On_Black ${NoColor}\n"
  printf "${On_Red} On_Red ${NoColor}\n"
  printf "${On_Green} On_Green ${NoColor}\n"
  printf "${On_Yellow} On_Yellow ${NoColor}\n"
  printf "${On_Blue} On_Blue ${NoColor}\n"
  printf "${On_Purple} On_Purple ${NoColor}\n"
  printf "${On_Cyan} On_Cyan ${NoColor}\n"
  printf "${On_White} On_White ${NoColor}\n"

# High Intensity
  printf "${IBlack} IBlack ${NoColor}\n"
  printf "${IRed} IRed ${NoColor}\n"
  printf "${IGreen} IGreen ${NoColor}\n"
  printf "${IYellow} IYellow ${NoColor}\n"
  printf "${IBlue} IBlue ${NoColor}\n"
  printf "${IPurple} IPurple ${NoColor}\n"
  printf "${ICyan} ICyan ${NoColor}\n"
  printf "${IWhite} IWhite ${NoColor}\n"

# Bold High Intensity
  printf "${BIBlack} BIBlack ${NoColor}\n"
  printf "${BIRed} BIRed ${NoColor}\n"
  printf "${BIGreen} BIGreen ${NoColor}\n"
  printf "${BIYellow} BIYellow ${NoColor}\n"
  printf "${BIBlue} BIBlue ${NoColor}\n"
  printf "${BIPurple} BIPurple ${NoColor}\n"
  printf "${BICyan} BICyan ${NoColor}\n"
  printf "${BIWhite} BIWhite ${NoColor}\n"

# High Intensity backgrounds
  printf "${On_IBlack} On_IBlack ${NoColor}\n"
  printf "${On_IRed} On_IRed ${NoColor}\n"
  printf "${On_IGreen} On_IGreen ${NoColor}\n"
  printf "${On_IYellow} On_IYellow ${NoColor}\n"
  printf "${On_IBlue} On_IBlue ${NoColor}\n"
  printf "${On_IPurple} On_IPurple ${NoColor}\n"
  printf "${On_ICyan} On_ICyan ${NoColor}\n"
  printf "${On_IWhite} On_IWhite ${NoColor}\n"
}

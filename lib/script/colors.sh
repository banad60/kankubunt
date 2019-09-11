#!/bin/bash
# kankubunt - cause it's with kanku ... und bunt too

black=`tput setaf 16`
blue=`tput setaf 21`
cyan=`tput setaf 51`
green=`tput setaf 46`
yellow=`tput setaf 226`
red=`tput setaf 196`
magenta=`tput setaf 201`
white=`tput setaf 231`

grey=`tput setaf 8`
dimblue=`tput setaf 4`
dimcyan=`tput setaf 6`
dimgreen=`tput setaf 2`
dimyellow=`tput setaf 3`
dimred=`tput setaf 1`
dimmagenta=`tput setaf 5`
dimwhite=`tput setaf 7`

pink=`tput setaf 213`
ocker=`tput setaf 172`
brown=`tput setaf 52`
apricot=`tput setaf 215`
orange=`tput setaf 208`
blutorange=`tput setaf 202`
limeyellow=`tput setaf 190`
lemon=`tput setaf 118`
powderblue=`tput setaf 153`
seegreen=`tput setaf 49`
darkred=`tput setaf 88`
indigo=`tput setaf 57`
violett=`tput setaf 93`
marineblue=`tput setaf 18`
babyblue=`tput setaf 39`
azur=`tput setaf 27`

bg_red=`tput setab 196`
bg_green=`tput setab 46`
bg_blue=`tput setab 21`
bg_yellow=`tput setab 226`
bg_magenta=`tput setab 201`
bg_cyan=`tput setab 51`
bg_white=`tput setab 231`
bg_black=`tput setab 16`

bg_dimred=`tput setab 1`
bg_dimgreen=`tput setab 2`
bg_dimblue=`tput setab 4`
bg_dimyellow=`tput setab 3`
bg_dimmagenta=`tput setab 5`
bg_dimcyan=`tput setab 6`
bg_dimwhite=`tput setaf 7`
bg_grey=`tput setab 8`

bg_darkgreen=`tput setab 22`
bg_seegreen=`tput setab 50`
bg_darkred=`tput setab 88`
bg_marineblue=`tput setab 18`


bold=`tput bold`    # Select bold mode
dim=`tput dim`      # Select dim (half-bright) mode
smul=`tput smul`    # Enable underline mode
rmul=`tput rmul`    # Disable underline mode
rev=`tput rev`      # Turn on reverse video mode
smso=`tput smso`    # Enter standout (bold) mode
rmso=`tput rmso`    # Exit standout mode

reset=`tput sgr0`

# traffic control signals
TFS1=${dimred}
TFS2=${dimyellow}
TFS3=${dimgreen}

# some format helpers
SPACER=${orange}'|'${TFS3}
SLASH=${orange}"\/"${TFS3}
BRK1_L=${orange}']'${TFS3}
BRK1_R=${orange}'['${TFS3}
LT=${orange}'<'${TFS3}
GT=${orange}'>'${TFS3}
BQ1=${orange}'"'${TFS3}
ARROW_R=${orange}' -> '${TFS3}
ARROW_L=${orange}' <- '${TFS3}

#FIN

#!/bin/bash
# kankubunt - cause it's with kanku ... und bunt too

DEBUG=
dbgMSG=
dbgCMD=
prnDEBUG () {
if [ ! -z $DEBUG ] && [[ $DEBUG -gt 0 ]]; then
   printf "${grey}%-25s > %-35s${reset}\n" "$dbgCMD"  "$dbgMSG"
fi
}

prnDEBUG_in () {
if [ ! -z $DEBUG ] && [[ $DEBUG -gt 0 ]]; then
   printf "${dimyellow}%-25s > %-35s${reset}\n" "$dbgCMD"  "$dbgMSG"
fi
}

prnDEBUG_red () {
if [ ! -z $DEBUG ] && [[ $DEBUG -gt 0 ]]; then
   printf "${dimred}%-25s > %-35s${reset}\n" "$dbgCMD"  "$dbgMSG"
fi
}

prnDEBUG_green () {
if [ ! -z $DEBUG ] && [[ $DEBUG -gt 0 ]]; then
   printf "${dimgreen}%-25s > %-35s${reset}\n" "$dbgCMD"  "$dbgMSG"
fi
}

prnDEBUG1 () {
if [ ! -z $DEBUG ] && [[ $DEBUG -gt 0 ]]; then
   printf "%-25s : %20s = %-35s\n" "$dbgCMD" "SOURCEIMAGEFILENAME" "$SOURCEIMAGEFILENAME"
fi
}

prnDEBUG2 () {
if [ ! -z $DEBUG ] && [[ $DEBUG -gt 0 ]]; then
   printf "%-25s : %20s = %-35s / %-25s\n" "$dbgCMD" "imagefile" "$imagefile" "$domain"
fi
}

prnDEBUG1_red () {
if [ ! -z $DEBUG ] && [[ $DEBUG -gt 0 ]]; then
   printf "${dimred}%-25s : %20s = %-35s${reset}\n" "$dbgCMD" "SOURCEIMAGEFILENAME" "$SOURCEIMAGEFILENAME"
fi
}
prnDEBUG2_red () {
if [ ! -z $DEBUG ] && [[ $DEBUG -gt 0 ]]; then
   printf "${dimred}%-25s : %20s = %-35s / %-25s${reset}\n" "$dbgCMD" "imagefile" "$imagefile" "$domain"
fi
}

prnDEBUG1_green () {
if [ ! -z $DEBUG ] && [[ $DEBUG -gt 0 ]]; then
   printf "${dimgreen}%-25s : %20s = %-35s${reset}\n" "$dbgCMD" "SOURCEIMAGEFILENAME" "$SOURCEIMAGEFILENAME"
fi
}
prnDEBUG2_green () {
if [ ! -z $DEBUG ] && [[ $DEBUG -gt 0 ]]; then
   printf "${dimgreen}%-25s : %20s = %-35s / %-25s${reset}\n" "$dbgCMD" "imagefile" "$imagefile" "$domain"
fi
}


# usage compareArray <inARRAY> <compareSTRING> # return 255 if not found or the KEY of the array
compareArray () {
      local inARRAY=$1
      local compareSTRING=$2
      local i=
      local RET=0

      IFS=$'\n' read -d '' -r -a records < ${inARRAY}
      for (( i=0; $i < ${#records[@]}; i+=1 )); do

            if [ ! -z $DEBUG ] && [[ $DEBUG -gt 0 ]]; then
                  dbgCMD="$i"
                  printf "${dimmagenta}%25s : %20s = %-35s${reset}\n" "$dbgCMD" "\${records[$i]}" "${records[$i]}"
            fi

            if [ "${records[$i]}" == "${compareSTRING}" ]; then
                  RET=0
                  break
            else
                  (( RET+=1 ))
            fi
      done

      if [[ $RET -eq ${#records[@]} ]]; then
               return 255
      else
               return $i
      fi
}


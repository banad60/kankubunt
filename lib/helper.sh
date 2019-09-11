#!/bin/bash
# kankubunt - cause it's with kanku ... und bunt too

. lib/script/colors.sh

# vars
TIMESTAMP=$(date +%Y%m%d%H%M%S)

export PATH=$(pwd):$PATH;
export PWD_old=$(pwd)


## functione ##
repeatChar () {
      local COUNTDOWN=$1
      local CHARACTER=$2
      for ((i=1; i<=$COUNTDOWN; i++)); do echo -n ${CHARACTER}; done
}


Stamp () {
     STAMP="["$(date +%Y)"/"$(date +%m)"/"$(date +%d)" "$(date +%H)":"$(date +%M)":"$(date +%S)"]"
}


logStamp () {
     Stamp
     #export LOGSTAMP=$(echo "${STAMP}" | sed 's/^[ \t]*//;s/[ \t]*$//')
     export LOGSTAMP=$(echo "${STAMP}")
}


repeatChar () {
      local COUNTDOWN=$1
      local CHARACTER=$2
      for ((i=1; i<=$COUNTDOWN; i++)); do echo -n ${CHARACTER}; done
}


titleheader () {
      local TITLE=$1
      local COLOR=$(echo -n $2);
      local TITLElenght=${#TITLE}
      local CHAR='━'
      #local CHAR='╍'
      #local CHAR='┅'
      #local CHAR='┉'

      #local DEKO_L='┍'
      #local DEKO_R='┑'
      #local DEKO_L='╸'
      #local DEKO_R='╺'
      local DEKO_L='━'
      local DEKO_R='━'

      local COLS=78
      ((  DEKOlenght = ((COLS - ( TITLElenght + 4 )) / 2) ))

      DEKO=$(repeatChar $DEKOlenght $CHAR)
      printf "${COLOR}${DEKO_L}%s  ${bold}${white}%s${reset}  ${COLOR}%s${DEKO_R}${reset}\n" "$DEKO" "$TITLE" "$DEKO"
}


printlog () {
      logStamp
      local CMD=$1
      local MSG=$2
      printf "${dimgreen}%s ${dimcyan}%-35s: ${dimmagenta}%s${reset}\n" "${LOGSTAMP}" "$MSG" "$CMD"
}


printlog_result () {
      logStamp
      local CMD=$1
      local MSG=$2
      printf "${dimgreen}%s ${dimcyan}%-35s: ${white}%s${reset}\n" "${LOGSTAMP}" "$MSG" "$CMD"
}


printlog_result_err () {
      logStamp
      local CMD=$1
      local MSG=$2
      printf "${dimgreen}%s ${red}%-35s: ${dimred}%s${reset}\n" "${LOGSTAMP}" "$MSG" "$CMD"
}


printlog_embedded () {
      logStamp
      local CMD=$1
      local MSG=$2
      printf "${dimmagenta}%s: ${dimmagenta}%s${reset}\n" "$MSG" "$CMD"
}


printlog_function () {
      logStamp
      local CMD=$1
      local MSG=$2
      printf "${dimyellow}%s ${dimblue}%-35s: ${babyblue}%s${reset}\n" "${LOGSTAMP}" "$MSG" "$CMD"
}


printlog_function_noCFL () {
      logStamp
      local CMD=$1
      local MSG=$2
      printf "${dimyellow}%s ${dimblue}%-35s: ${babyblue}%s${reset}" "${LOGSTAMP}" "$MSG" "$CMD"
}


printlog_function_in () {
      logStamp
      local CMD=$1
      local MSG=$2
      printf "${dimyellow}%s ${dimblue}%-35s: ${dimyellow}%s${reset}\n" "${LOGSTAMP}" "$MSG" "$CMD"
}


printlog_function_out () {
      logStamp
      local CMD=$1
      local MSG=$2
      printf "${dimyellow}%s ${dimblue}%-35s: ${white}%s${reset}\n" "${LOGSTAMP}" "$MSG" "$CMD"
}


printlog_function_out_long () {
      logStamp
      local CMD=$1
      local MSG=$2
      printf "${dimyellow}%s ${dimblue}%s ${white}%s${reset}\n" "${LOGSTAMP}" "$MSG" "$CMD"
}


printlog_list () {
      logStamp
      local CMD=$1
      local MSG=$2
      local NUM=$3
      local FNAME=$4
      printf "${grey}%s ${dimblue}%-33s ${dimcyan}%2s.) ${dimblue}%s = ${dimcyan}%s${reset}\n" "${LOGSTAMP}" "$FNAME" "$NUM" "$MSG" "$CMD"
}

######

fileExist () { if [ -e "$1" ] ; then  return 0; else return 1; fi;}
dirExist () { if [ -d "$1" ] ; then return 0; else return 1; fi; }


usrExist () {
   USR=`getent passwd $1  >/dev/null; echo $?;`
   return $USR
}


grpExist () {
   GRP=`getent group $1  >/dev/null; echo $?`
   return $GRP
}


# usage isGroupMember <group> <user>
isGroupMember () {
   MEMBER=`getent group $1 | grep &>/dev/null "\b${2}\b"; echo $?`
   return $MEMBER
}


isInstalled () { sudo dpkg -s $1 >/dev/null 2>&1; return $?; }


isActive () {
      if [ -z $1 ]; then
            printf " * miss : -> %s\n" "arg"
            return 2;
      else
         local STATUS=`systemctl is-active $1`
         if  [ "$STATUS" == "active" ]; then
            printf " *  status: -> %s\n" "$1 is running"
            return 0;
         else
            printf " *  status: -> %s\n" "$1 not running"
            return 1;
         fi;
      fi;
};


isEnabled () {
      if [ -z $1 ]; then
            printf " * miss : -> %s\n" "arg"
            return 2;
      else
         local STATUS=`systemctl is-enabled $1`
         if  [ "$STATUS" == "enabled" ]; then
            printf " *  status: -> %s\n" "$1 is enabled"
            return 0;
         else
            printf " *  status: -> %s\n" "$1 not enabled"
            return 1;
         fi;
      fi;
};


isMasked () {
      local SERVICE=$1
      local STATUS=`systemctl list-unit-files | grep $SERVICE | tr -s ' '| cut -d ' ' -f 2`
      if  [ "$STATUS" == "masked" ]; then return 0; else return 1; fi
};


mask () {
      echo -n " *    mask: -> " && sudo systemctl mask $1
}


unmask () {
      echo -n " *  unmask: -> " && sudo systemctl unmask $1
}


enable () {
   if ! isEnabled $1; then
      printf " >    todo: -> %s\n" "enable $1"
      sudo systemctl enable $1
   fi;
}


disable () {
   if isEnabled $1; then
      printf " >    todo: -> %s\n" "disable $1"
      sudo systemctl disable $1
   fi;
}


reenable () {
   if ! isEnabled $1; then
      printf " >    todo: -> %s\n" "reenable $1"
      sudo systemctl reenable $1
   fi;
}


start () {
   if ! isActive $1; then
      printf " >    todo: -> %s\n" "start $1"
      sudo systemctl start $1
   fi;
}


restart () {
   if isActive $1; then
      printf " >    todo: -> %s\n" "restart $1"
      sudo systemctl restart $1
   fi;
}


stop () {
   if isActive $1; then
      printf " >    todo: -> %s\n" "stop $1"
      sudo systemctl stop $1
   fi;
}


install () {
   if ! isEnabled $1; then
      sudo systemctl enable $1
   fi;
   if ! isActive $1; then
      sudo systemctl start $1
   fi;
}


uninstall () {
   if  isActive $1; then
      sudo systemctl stop $1
   fi;
   if isEnabled $1; then
      sudo systemctl disable $1
   fi;
}


apt-get_install () {
   if isInstalled $1; then
         printf " *   exist: -> %s\n" "$1 seems to be installed"
   else
         printf " *    miss:  -> %s\n" "$1 not installed - install it"
         sudo apt-get -y install $1
   fi;
}


apt-get_remove () {
   if isInstalled $1; then
         printf " *   exist: -> %s\n" "$1 is installed - remove it"
         sudo apt-get -y remove $1
   else
         printf " *    miss:  -> %s\n" "$1 seems not to be installed"
   fi;
}


apt-get_purge () {
   if isInstalled $1; then
         printf " *   exist: -> %s\n" "$1 is installed - purge it"
         sudo apt-get -y purge $1
   else
         printf " *    miss:  -> %s\n" "$1 seems not to be installed"
   fi;
}


service_enable () {
      local SERVICE=$1
      if isActive $SERVICE; then
            printf " * restart: -> %s\n" "$SERVICE"
            sudo systemctl restart $SERVICE
      else
            if isEnabled $SERVICE; then
                  printf " *  start: -> %s\n" "$SERVICE"
                  sudo systemctl start $SERVICE
            else
                  #sudo systemctl unmask postfix.service
                  if isMasked $SERVICE; then
                        unmask $SERVICE
                  fi
                  printf " *  enable: -> %s\n" "$SERVICE"
                  sudo systemctl enable $SERVICE  >/dev/null 2>&1;
                  printf " *   start: -> %s\n" "$SERVICE"
                  sudo systemctl start $SERVICE
            fi;
      fi;
}


service_disable () {
      local SERVICE=$1
      if isActive $SERVICE; then
            printf " *    stop: -> %s\n" "$SERVICE"
            sudo systemctl stop $SERVICE
            printf " * disable: -> %s\n" "$SERVICE"
            sudo systemctl disable $SERVICE >/dev/null 2>&1;
      fi;
}


backup_file () {
      local FILE=$1
      local BACKUPTIME=$(date +%Y%m%d%H%M%S)

      if [ ! -z $2 ]; then
         local SRC=$2
      else
         local SRC="fakeroot"$FILE
      fi


      local DIRNAME=`dirname "$FILE"`
      local FILENAME=`basename "$FILE"`

      local thisCMD=$(sudo mv $FILE $FILE.$BACKUPTIME.bak && echo "$FILE -> $FILE.$BACKUPTIME.bak")
      local thisMSG="${FUNCNAME[0]} mv"
      printlog_function_out "$thisCMD" "$thisMSG"

      echo -n ${grey}
      sudo git diff --color "$FILE.$BACKUPTIME.bak" "$SRC"| sudo tee -a $FILE.$BACKUPTIME.patch

      local GROUP=$(id -g -n $USER)
      local thisCMD=$(sudo chown -Rv $USER:$GROUP $FILE.$BACKUPTIME.patch) && thisMSG="${FUNCNAME[0]} chown" && printlog_function_out "$thisCMD" "$thisMSG"

      echo -n ${reset}

      local thisCMD=$(sudo ln -sfv $FILENAME.$BACKUPTIME.bak $FILE.last.bak) && local thisMSG="${FUNCNAME[0]} ln" && printlog_function_out "$thisCMD" "$thisMSG"
      local thisCMD=$(sudo ln -sfv $FILENAME.$BACKUPTIME.patch $FILE.last.patch) && local thisMSG="${FUNCNAME[0]} ln" && printlog_function_out "$thisCMD" "$thisMSG"

      # verschnaufpause, weil i bin z'schnöö fia de wööd und überschreib wieder ois in ner sekundn ;-)
      sleep 1
}


setup_file () {
      local SRC=$1
      local FILE=$2
      local GROUP=$(id -g -n $USER)

      if fileExist $FILE; then
            local thisCMD=$(echo "$FILE exists") && local thisMSG="${FUNCNAME[0]} status" && printlog_function_in "$thisCMD" "$thisMSG"
            DIFFMSG=`sudo diff -s $SRC $FILE`
            DIFF=`echo $?`
            if [ "$DIFF" == "1" ]; then
               # backup first
               backup_file $FILE $SRC
               local thisCMD=$(sudo cp -v $SRC $FILE) && local thisMSG="${FUNCNAME[0]} copy" && printlog_function_out "$thisCMD" "$thisMSG"

            else
               local thisCMD=$(echo "nothing modified ${BRK1_R}DIFF=${DIFF}${BRK1_L}") && local thisMSG="${FUNCNAME[0]} status" && printlog_function_out "$thisCMD" "$thisMSG"
            fi
      else
            local thisCMD=$(echo "$FILE do not exist - copy $SRC") && local thisMSG="${FUNCNAME[0]} status" && printlog_function_in "$thisCMD" "$thisMSG"
            local thisCMD=$(sudo cp -v $SRC $FILE) && local thisMSG="copy" && printlog_function_out "$thisCMD" "$thisMSG"
      fi;

      local thisthisCMD=$(sudo chown -Rv $USER:$GROUP $FILE) && thisthisthisMSG="${FUNCNAME[0]} chown" && printlog_function_out "$thisCMD" "$thisMSG"
}


unset_file () {
      local FILE=$1
      if fileExist $FILE; then
            local CMD_RM=$(sudo rm -fv $FILE)
            printf "${dimmagenta} *  remove: ${dimred}%s\n" "$CMD_RM"
      else
            printf "${dimmagenta} *  status: ${grey}%s${reset}\n" "$FILE do not exist"
      fi;
}


db_inject () {
      local FILE=$1
      local SRC="files"$FILE
      if fileExist $FILE; then
         DIFFMSG=`sudo diff -s $SRC $FILE`
         DIFF=`echo $?`
         if [ "$DIFF" == "1" ]; then
               echo -n " ~    move: -> " && sudo mv -v $FILE $FILE.posfix.$TIMESTAMP.bak
               sudo ln -sf $FILE.posfix.$TIMESTAMP.bak $FILE.posfix.last.bak
               wait

               setup_file "$SRC" "$FILE";
               wait

               #inject the diff between /etc/aliases.posfix.last.bak to /etc/aliases
               echo " /    diff: -> "$DIFFMSG;
               local EDFILE=$FILE"-ed-script.txt"
               sudo diff -e -b -B $FILE $FILE.posfix.last.bak | sudo tee -a $EDFILE &>/dev/null;
               sudo echo "w" | sudo tee -a $EDFILE &>/dev/null;
               sudo ed - $FILE < $EDFILE
               echo -n " -  remove: -> " && sudo rm -v $EDFILE
               wait
         else
               # check /etc/aliases for 'root:' entry
               thishasRoot=`sudo cat $FILE|grep 'root:'|tr -d ' '`
               echo " *  status: -> "$DIFFMSG" "$thishasRoot" DIFF="$DIFF
         fi
         local DIFF=
         local DIFFMSG=
      else
          setup_file "$SRC" "$FILE";
      fi;
      echo -n " ~   chmod: -> " && sudo chmod -v 600 $FILE

      #sudo newaliases;
      MSG=`sudo postmap -v $FILE 2>&1 | sed 's/postmap: /-> /g' | sed 's/^[ \t]*//;s/[ \t]*$//'`
      echo " * postmap: "$MSG
}


# usage proofMemmership <group> <user>
isMember () {
      if usrExist $2; then
         printf " *  status: -> %s\n" "user $2 exist";
         if grpExist $1; then
            printf " *  status: -> %s\n" "group $1 exist"

            if isGroupMember $1 $2; then
               printf " *  status: -> %s\n" "user $2 is member of group $1"
               return 0;
            else
               printf " *  status: -> %s\n" "group $1 has no member $2"
               return 1;
            fi;

         else
            printf " *  status: -> %s\n" "no group $1"
            return 2;
         fi;
      else
         printf " *  status: -> %s\n" "no user $2"
         return 3;
      fi;
}


# usage: addMember <user> <group>
addMember () {
      thisUSER=$1
      thisGROUP=$2
      isMember $thisGROUP $thisUSER
      RET=`isMember $thisGROUP $thisUSER >/dev/null; echo $?`
      if [ $RET -eq 1 ]; then
            printf " >    todo: -> %s\n" "add membership"
               sudo usermod -a -G $thisGROUP $thisUSER
      else
            printf " >    todo: -> %s\n" "nothing"
      fi
}


# usage: delMember <user> <group>
delMember () {
      thisUSER=$1
      thisGROUP=$2
      if isMember $thisGROUP $thisUSER; then
            printf " >    todo: -> %s\n" "delete membership"
            sudo deluser $thisUSER $thisGROUP
      else
            printf " >    todo: -> %s\n" "nothing"
      fi
}


# usage: addUser <user> <group> <comment>
addUser () {
      thisUSER=$1
      thisGROUP=$2
      thisCOMMENT=$3
      if ! usrExist $thisUSER; then
            printf " >    todo: -> %s\n" "add user $thisUSER"
            sudo useradd -d /dev/null -g "$thisGROUP" -c "$thisCOMMENT" -s /dev/null -M "$thisUSER";
      else
            printf " >    todo: -> %s\n" "nothing - user $thisUSER exists"
      fi
}


# usage: delUser <user>
delUser () {
      thisUSER=$1
      if usrExist $thisUSER; then
            printf " >    todo: -> %s\n" "delete user $thisUSER"
            sudo deluser $thisUSER
      else
            printf " >    todo: -> %s\n" "nothing"
      fi
}


# usage: addGroup <group>
addGroup () {
      thisGROUP=$1
      if ! grpExist $thisGROUP; then
            printf " >    todo: -> %s\n" "add group $thisGROUP"
            sudo groupadd $thisGROUP
      else
            printf " >    todo: -> %s\n" "nothing - group $thisGROUP exists"
      fi
}


# usage: addGroup <group>
delGroup () {
      thisGROUP=$1
      if grpExist $thisGROUP; then
            printf " >    todo: -> %s\n" "delete group $thisGROUP"
            sudo groupdel $thisGROUP
      else
            printf " >    todo: -> %s\n" "nothing"
      fi
}


# usage: parseTemplate <template> <outfile>
parseTemplate () {
      if fileExist ${2}; then
         rm -f ${2}
      fi
      ( echo "cat <<EOF | sed 's/[ \t]*$//' | sed '/./!d' >${2}";
        cat ${1};
        echo "EOF";
      )  >/tmp/temp.yml
      . /tmp/temp.yml
      echo "${orange}*${grey}###${white}- parseTemplate: ${1} -> ${2} -${grey}###"
      cat ${2}
      echo "${reset}"
      if fileExist /tmp/temp.yml; then
         rm -f /tmp/temp.yml
      fi
}


#usage: addFIRSTLINE <text> <file>
addFIRSTLINE() {
        local text_to_add="$1"
        local install_to="$2"
        tmp=$(mktemp /tmp/tmp.XXX)

        added=0
        while IFS=$'\n' read -r line ; do
                printf "$line\n" >> "$tmp"
                [ $added = 0 ] && grep -q '^#' <<<"$line" && printf "${text_to_add}\n" >>"$tmp" && added=1
        done < "$install_to"

        mv -f "$tmp" "$install_to"
}
alias addFIRSTLINE-su='bash -c "$(declare -f addFIRSTLINE); addFIRSTLINE"'


deleteDOUBBLELINES() {
      local thisINFILE="$1"
      #local thisCMD=$(cp $thisINFILE $thisTMP && echo $thisINFILE)
      local thisCMD=$(echo $thisINFILE)
      local thisMSG="${FUNCNAME[0]} check"
      printlog_function_in "$thisCMD" "$thisMSG"

      local thisTMP=$(mktemp /tmp/tmp.XXX)

      # check for doubble lines
      sort $thisINFILE | uniq -d  > $thisTMP

      local thisDOUBLES=$(cat $thisTMP)

      if [ ! -z "$thisDOUBLES" ]; then
            echo "${red}* ${grey}###- ${dimwhite}doubble entrys${grey} -###"
            echo "${red}${thisDOUBLES}"

            echo "${grey} --  $thisINFILE clean:"
            #sort $thisINFILE | uniq -cz | sed '/^$/d' | sed 's/.$//' > $thisTMP
            sort $thisINFILE | uniq -u > $thisTMP

            # backup and create patch
            local thisCMD=$(echo $thisTMP) && thisMSG="${FUNCNAME[0]} thisTMP" && printlog_function "$thisCMD" "$thisMSG"

            #local FILE=$thisINFILE
            local thisCMD=$(echo $thisINFILE ) && thisMSG="${FUNCNAME[0]} thisINFILE" && printlog_function "$thisCMD" "$thisMSG"

            diff -s "$thisTMP" "$thisINFILE" >/dev/null
            local DIFF=$(echo $?)

            if [ "$DIFF" == "1" ] || [ "$DIFF" == "2" ]; then
               backup_file $thisINFILE $thisTMP

               local thisCMD=$(mv -v $thisTMP $thisINFILE) && thisMSG="${FUNCNAME[0]} out0a move" && printlog_function_out "$thisCMD" "$thisMSG"

               local GROUP=$(id -g -n $USER)
               local thisCMD=$(sudo chown -Rv $USER:$GROUP $thisINFILE) && thisMSG="${FUNCNAME[0]} chown" && printlog_function_out "$thisCMD" "$thisMSG"

            else
               local thisCMD=$(echo $DIFF) && thisMSG="${FUNCNAME[0]} out0b DIFF" && printlog_function_out "$thisCMD" "$thisMSG"
            fi
            local thisCMD=$(echo "$thisINFILE cleaned") && thisMSG="${FUNCNAME[0]} out0" && printlog_function_out "$thisCMD" "$thisMSG"
      else
            rm $thisTMP
            local thisCMD=$(echo "no double lines") && thisMSG="${FUNCNAME[0]} out1" && printlog_function_out "$thisCMD" "$thisMSG"
      fi
}
alias deleteDOUBBLELINES_su='bash -c "$(declare -f deleteDOUBBLELINES); deleteDOUBBLELINES"'

alias sudo='sudo '


# usage: isYES <text> <timeout>
isYES() {
      local TEXT_QUESTION=$1
      local TIMEOUT=$2
      if [ -z $2 ]; then local TIMEOUT=7; else local TIMEOUT=$2; fi

      while true; do
            read -t ${TIMEOUT} -p "${red}!${white}${TEXT_QUESTION}${red}? ${BRK1_R}y/n${BRK1_L} " YN
            # check if timout has expired - with no input, kick out
            if [ $? -gt 128 ]; then echo "" && exit 1; fi
            # sitch y/n
            case $YN in
                [yY]* ) return 0; break; ;;
                [nN]* ) return 1; continue; ;;
                     *) nn; ;;
            esac;
      done;
}


## Input from stdin
#read_from_pipe() { read "$@" <&0; }
#back=0;
parse_stdin() {
      PFILE="$1";
      O_FLAG=0;
      while true; do
      #echo "O_FLAG=$O_FLAG";
          if [ -s $PFILE ] && [ $O_FLAG -eq 0 ] ;then
               echo " !! ERROR - can not parse, because file exists an is not empty";
               read -p " !! overwirte exitsting FILE? [y/n] " YN

               case $YN in
                   [yY]* ) O_FLAG=1; continue; ;;
                   [nN]* ) return 1; break; ;;
                        *) continue; ;;
               esac;
          else
               echo " *  PFILE not exists - working ....";
               BACKIFS="$IFS";
               IFS=;
               read -d '' -n 1 INPUT;
               while IFS= read  -d '' -n 1 -t 2 TMP;
               do
                   INPUT+=$TMP;
               done;
               IFS=$BACKIFS;
               echo " ";
               if [ -z "$INPUT" ] ; then
                     echo " !! ERROR - No input!";
                     return 1;
                     break
               else
                     echo " *  Thanks!";
                     echo "$INPUT" > $PFILE;
                     echo " ";
                     return 0;
                     break
               fi;
          fi;
      done;
} #EOF parse_stdin()


#load virsh-helpers library
. lib/script/virsh-helpers.sh

. lib/script/isOnline.sh


#FIN


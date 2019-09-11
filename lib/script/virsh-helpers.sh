#!/bin/bash
# kankubunt - cause it's with kanku ... und bunt too

arrayView () {
   local ARRAY=$1
   local KEYS=(${!ARRAY[@]});
   for (( i=0; $i < ${#ARRAY[@]}; i+=1 )); do
         local KEY=${KEYS[$i]};
         local NUM=$KEY && ((NUM+=1)); # linecount
         local thisCMD=$(echo "${ARRAY[$KEY]}")
         local thisMSG='$ARRAY['$KEY"]"
         printlog_list "$thisCMD" "$thisMSG" "$NUM" "${FUNCNAME[0]}"
   done;
}


existVMDOMAIN () {
   local domainName=$1;
   local thisLIBVIRTHOST=$2;
   if [ ! -z $thisLIBVIRTHOST ]; then
         local thisTmp=$(virsh -c qemu+ssh://root@${thisLIBVIRTHOST}/system list --all | grep " ${domainName} " | awk '{ print $3}')
   else
         local thisTmp=$(sudo virsh -c qemu:///system list --all | grep " ${domainName} " | awk '{ print $3}')
   fi
   local thisCMD=$(echo "VM \"${domainName}\"")
   if [ -z $thisTmp ]; then
       local thisMSG="${FUNCNAME[0]} (1)"
       if [ -z $QUIET ]; then printlog_function_out "${TFS2}$thisCMD  does not exist" "$thisMSG"; fi
       return 1
   else
       local thisMSG="${FUNCNAME[0]} (0)"
       if [ -z $QUIET ]; then printlog_function_out "${TFS3}$thisCMD exist" "$thisMSG"; fi;
       return 0
   fi
} #EOF existVMDOMAIN ()


isVMDOMAINrunning () {
   local domainName=$1;
   local thisLIBVIRTHOST=$2;
   if [ -z $3 ]; then local EMBED=; else local EMBED=1; fi
   if [ ! -z $thisLIBVIRTHOST ]; then
         local thisTmp=$(virsh -c qemu+ssh://root@${thisLIBVIRTHOST}/system list --state-running | grep " ${domainName} " | awk '{ print $3}')
   else
         local thisTmp=$(sudo virsh -c qemu:///system list --state-running | grep " ${domainName} " | awk '{ print $3}')
   fi

   local thisCMD=$(echo "VM \"${domainName}\"")
   if [ -z $thisTmp ]; then
         if [ -z ${EMBED} ]; then
             local thisMSG="${FUNCNAME[0]} (1)" && printlog_function_out "${TFS2}$thisCMD is not running" "$thisMSG"
         else
             local thisMSG=' ' && printlog_embedded "${TFS2}$thisCMD is not running" "$thisMSG"
         fi
         return 1;
   else
         if [ -z ${EMBED} ]; then
             local thisMSG="${FUNCNAME[0]} (0)" && printlog_function_out "${TFS3}$thisCMD $thisTmp" "$thisMSG"
         else
             local thisMSG=' ' && printlog_embedded "${TFS3}$thisCMD $thisTmp" "$thisMSG"
         fi
         return 0;
   fi
} #EOF isVMDOMAINrunning ()


getVMDOMAIN_arr () {
   local domainName=$1;
   local thisCMD=$(echo ${domainName})
   local thisMSG="${FUNCNAME[0]} domainName (in)"
   if [ -z $QUIET ]; then printlog_function_in "$thisCMD" "$thisMSG"; fi

   local thisLIBVIRTHOST=$2;
   local thisCMD=$(echo ${thisLIBVIRTHOST})
   local thisMSG="${FUNCNAME[0]} LIBVIRTHOST (in)"
   if [ -z $QUIET ]; then printlog_function_in "$thisCMD" "$thisMSG"; fi

   local tmpmac=$(mktemp /tmp/ifmac.XXX)
   if [ ! -z $thisLIBVIRTHOST ]; then
         virsh -c qemu+ssh://root@${thisLIBVIRTHOST}/system  domiflist ${domainName} | egrep '.?.?:.*:.*:.?.?' | sed 's/^[ \t]*//' | tr -s ' ' | sed -e 's/-/none/g'  | tr "[:space:]" "\n" > $tmpmac
   else
         sudo virsh domiflist ${domainName} | egrep '.?.?:.*:.*:.?.?' | sed 's/^[ \t]*//' | tr -s ' ' | sed -e 's/-/none/g'  | tr "[:space:]" "\n" > $tmpmac
   fi
   DOM_NIF=(`cat $tmpmac`)
   export DOM_NIF
   export KEYS=(${!DOM_NIF[@]});
   for (( i=0; $i < ${#DOM_NIF[@]}; i+=1 )); do
         local KEY=${KEYS[$i]};
         local NUM=$KEY && ((NUM+=1)); # linecount
         local thisCMD=$(echo "${DOM_NIF[$KEY]}")
         local thisMSG='$DOM_NIF['$KEY"]"
         printlog_list "$thisCMD" "$thisMSG" "$NUM" "${FUNCNAME[0]}"
   done;
   rm $tmpmac
} #EOF getVMDOMAIN_arr ()


# usage:  getVM_MAC <domainname>
getVM_MAC () {
      local thisDOMAIN=${1} && local thisCMD=$(echo "${thisDOMAIN}") && local thisMSG="${FUNCNAME[0]} thisDOMAIN" && printlog_function_in "$thisCMD" "$thisMSG"
      local thisLIBVIRTHOST=$2 && local thisCMD=$(echo "${thisLIBVIRTHOST}") && local thisMSG="${FUNCNAME[0]} thisLIBVIRTHOST" && printlog_function_in "$thisCMD" "$thisMSG"
      if [ ! -z $thisLIBVIRTHOST ]; then
            local thisMAC=$(virsh -c qemu+ssh://root@${thisLIBVIRTHOST}/system  dumpxml ${thisDOMAIN} | grep 'mac address' | awk -F\' '{ print $2}') ;  #\'
            local thisCMD=$(echo "${thisMAC}") && local thisMSG="${FUNCNAME[0]} out 0"
      else
            local thisMAC=$(sudo virsh dumpxml ${thisDOMAIN} | fgrep --no-messages 'mac address' | awk -F\' '{ print $2}') ;  #\'
            local thisCMD=$(echo "${thisMAC}") && local thisMSG="${FUNCNAME[0]} out 1"
      fi
      printlog_function_out "$thisCMD" "$thisMSG"
} #EOF getVM_MAC ()


# usage:  getVM_IPfromMAC <mac>
getVM_IPfromMAC () {
      local thisMAC=${1}
      local thisDOMAIN=${2}
      local thisLIBVIRTHOST=${3}
      local tmpips=$(mktemp /tmp/tmpips.XXX);
      if [ ! -z $thisLIBVIRTHOST ]; then
            local tmpips2=$(mktemp /tmp/tmpips.XXX);
            ssh -q -o "StrictHostKeyChecking no" -A root@${thisLIBVIRTHOST} -t "ip neigh | fgrep --no-messages ${thisMAC} | cut -d' ' -f1 | sed 's/^[ \t]*//;s/[ \t]*$//' | tr -s ' ' | tr '[:space:]' '\n'" > $tmpips;
            # fuck \r
            tr -d '\r' <$tmpips >$tmpips2
            mv $tmpips2 $tmpips
      else
            ip neigh | fgrep --no-messages ${thisMAC} | cut -d' ' -f1 | sed 's/^[ \t]*//;s/[ \t]*$//' | tr -s ' ' | tr '[:space:]' '\n' > $tmpips;
      fi
      declare -a thisIP_ARRAY=(`cat $tmpips`)
      export thisIP_ARRAY
      rm $tmpips
      thisKEYS=(${!thisIP_ARRAY[@]});
      isREACHABLE=
      for (( i=0; $i < ${#thisIP_ARRAY[@]}; i+=1 )); do
             thisKEY=${thisKEYS[$i]};
             thisIP=$(echo ${thisIP_ARRAY[$thisKEY]});
             tmpping=$(mktemp /tmp/tmpping.XXX)
             ping -w 1 ${thisIP} > $tmpping
             isREACHABLE=$?
            if [ -s $tmpping ] && [[ $isREACHABLE -eq 0 ]]; then
                  local PINGMSG=$(cat -v $tmpping | head -2 | tail -1 | tr -d '\r') # line 2
            fi
            rm $tmpping
            if [[ $isREACHABLE -eq 0 ]]; then thisSTAT=$(echo ${green}${isREACHABLE}); else thisSTAT=$(echo ${red}${isREACHABLE}); fi
            local thisVM_IP=${thisIP}
            local thisCMD=$(printf "${grey}isREACHABLE = %s ${dimblue}: ${grey}thisVM_IP = %-15s ${dimblue}: ${grey}%s" ${thisSTAT} ${thisVM_IP} "${PINGMSG}" );
            local thisMSG="${FUNCNAME[0]} (for in)";
            printlog_function "$thisCMD" "$thisMSG"
             VM_IP=
             if [[ $isREACHABLE -eq 0 ]]; then
                  local thisCMD=$(echo "${thisVM_IP}")
                  local thisMSG="${FUNCNAME[0]} (o0)"
                  printlog_function_out "$thisCMD" "$thisMSG"
                  export VM_IP=${thisVM_IP}
                  break
                  return 0
             else
                  if [ ! -z ${thisVM_IP} ]; then
                        iii=0
                        while true; do
                              # recursion
                              VM_IP=
                              getVM_IPfromMAC $thisMAC $thisDOMAIN $thisLIBVIRTHOST
                              local RET=$?
                              if [ ! -z $VM_IP ]; then
                                    # reset i
                                    i=${#thisIP_ARRAY[@]};
                                    break;
                              else
                                    sleep 1;
                              fi
                              local thisCMD=$(printf "%-6s: getVM_IPfromMAC:%s  thisIP :%-15s " "$iii" "$RET" "${thisIP}")
                              local thisMSG="${FUNCNAME[0]} recursion    count"
                              printlog_function_out "${grey}$thisCMD" "$thisMSG"
                              (( iii+=1 ))
                        done
                        export VM_IP=${thisIP}
                        return 0
                  else
                        local thisCMD=$(echo "no IP found")
                        local thisMSG="${FUNCNAME[0]} (o1.u1)"
                        printlog_function_out "$thisCMD" "$thisMSG"
                        return 1
                  fi
             fi
      done;
      return 0
} #EOF getVM_IPfromMAC ()


#usage: getVM_IPfromDOMAIN <domain>
getVM_IPfromDOMAIN () {
      local thisDOMAIN=${1}
      local thisCMD=$(echo "${thisDOMAIN}")
      local thisMSG="${FUNCNAME[0]} thisDOMAIN"
      if [ -z $QUIET ]; then printlog_function_in "$thisCMD" "$thisMSG"; fi

      local thisLIBVIRTHOST=$2;
      local thisCMD=$(echo "${thisLIBVIRTHOST}")
      local thisMSG="${FUNCNAME[0]} thisLIBVIRTHOST"
      if [ -z $QUIET ]; then printlog_function_in "$thisCMD" "$thisMSG"; fi

      if existVMDOMAIN ${thisDOMAIN} ${thisLIBVIRTHOST}; then
            if [ ! -z $thisLIBVIRTHOST ]; then
                  local thisMAC=$(virsh -c qemu+ssh://root@${thisLIBVIRTHOST}/system dumpxml ${thisDOMAIN} | grep 'mac address' | awk -F\' '{ print $2}')
            else
                  local thisMAC=$(sudo virsh -c qemu:///system dumpxml ${thisDOMAIN} | grep 'mac address' | awk -F\' '{ print $2}')
            fi
            getVM_IPfromMAC ${thisMAC} ${thisDOMAIN} ${thisLIBVIRTHOST}
            local RET=$?
            return $RET
      else
            local thisCMD=$(echo "${dimred}existVMDOMAIN=false - try 'kanku up'")
            local thisMSG="${FUNCNAME[0]} out1"
            printlog_function_out "$thisCMD" "$thisMSG"
            exit 1
      fi
} #EOF getVM_IPfromDOMAIN ()


# usage shutdownVMDOMAIN ${VM_DOMAIN} ${LIBVIRTHOST}
shutdownVMDOMAIN () {
      local domainName=$1;
      local thisLIBVIRTHOST=$2;
      printlog_function_in "$(echo ${domainName})" "${FUNCNAME[0]} domainName"
      printlog_function_in "$(echo ${thisLIBVIRTHOST})" "${FUNCNAME[0]} thisLIBVIRTHOST"
      if [ "$VM_NETWORK_TYPE" == 'dhcp' ]; then
            local ii=0
            QUIET=true
            while true; do
                  VM_IP=
                  getVM_IPfromDOMAIN ${domainName} ${thisLIBVIRTHOST};
                  RET=$?
                  if [ ! -z ${VM_IP} ]; then
                        local thisCMD=$(printf "%-6s: getVM_IPfromDOMAIN: %s | VM_IP: %-15s" "$ii" "$RET" "$VM_IP")
                        local thisMSG="${FUNCNAME[0]} dhcp         break"
                        printlog_function_out "${grey}$thisCMD" "$thisMSG"
                        break;
                  else
                        sleep 1;
                  fi
                  local thisCMD=$(printf "%-6s: getVM_IPfromDOMAIN:%s  VM_IP :%-15s " "$ii" "$RET" "$VM_IP")
                  local thisMSG="${FUNCNAME[0]} dhcp         count"
                  printlog_function_out "${grey}$thisCMD" "$thisMSG"
                  (( ii+=1 ))
            done
            QUIET=
      else
            VM_IP=${VM_IP4_STATIC}
      fi
      # call shutdown
      if [ ! -z $thisLIBVIRTHOST ]; then
            local thisCMD=$(virsh -c qemu+ssh://root@${thisLIBVIRTHOST}/system shutdown --domain ${domainName})
      else
            local thisCMD=$(sudo virsh shutdown --domain ${domainName})
      fi
      local thisMSG="${FUNCNAME[0]} virsh shutdown" && printlog_function "$thisCMD" "$thisMSG"
      # ... and wait till ... connetivity
      isOnline ${VM_IP} 22 'isDOWN' ${domainName} ${thisLIBVIRTHOST}
      FINISH=
      if [[ $isREACHABLE -eq 1 ]]; then
                  local thisCMD=$(echo "Domain ${domainName} seems to be offline")
                  local thisMSG="${FUNCNAME[0]} virsh shutdown"
                  printlog_function_out "$thisCMD" "$thisMSG"
                  FINISH=true
                  CURRENTSAT=1
       fi
      # ... and if VM is still running, then the wooden hammer.
      if [ -z ${FINISH} ]; then
            if [ ! -z $thisLIBVIRTHOST ]; then
                  local thisCMD=$(virsh -c qemu+ssh://root@${thisLIBVIRTHOST}/system destroy --domain ${domainName})
            else
                  local thisCMD=$(sudo virsh destroy --domain ${domainName})
            fi
            local thisMSG="destroy domain" && printlog_function_out "$thisCMD" "$thisMSG"
      fi
} #EOF shutdownVMDOMAIN


# usage: startupVMDOMAIN ${VM_DOMAIN} ${LIBVIRTHOST}
startupVMDOMAIN () {
      local domainName=$1;
      local thisLIBVIRTHOST=$2;
      if ! isVMDOMAINrunning ${domainName} ${thisLIBVIRTHOST}; then
           # call start
            if [ ! -z $thisLIBVIRTHOST ]; then
                  local thisCMD=$(virsh -c qemu+ssh://root@${thisLIBVIRTHOST}/system start --domain ${domainName})
            else
                  local thisCMD=$(sudo virsh start --domain ${domainName})
            fi
            local thisMSG="${FUNCNAME[0]} virsh start"
            printlog_function_in "$thisCMD" "$thisMSG"
      fi
      # ... and wait till ...
      if [ "${VM_NETWORK_TYPE}" == 'dhcp' ]; then
            # prepare ${VM_IP}
            local ii=0
            #if [ -z $isREACHABLE ] || [[ $isREACHABLE -eq 1 ]]; then
            QUIET=true
            while true; do
                  VM_IP=
                  getVM_IPfromDOMAIN ${domainName} ${thisLIBVIRTHOST};
                  RET=$?
                  if [ ! -z ${VM_IP} ]; then
                        local thisCMD=$(printf "%-6s: getVM_IPfromDOMAIN: %s | VM_IP: %-15s" "$ii" "$RET" "$VM_IP")
                        local thisMSG="${FUNCNAME[0]} dhcp         break"
                        printlog_function_out "${grey}$thisCMD" "$thisMSG"
                        export VM_IP
                        break;
                  else
                        sleep 1;
                  fi
                  (( ii+=1 ))
                  local thisCMD=$(printf "%-6s: getVM_IPfromDOMAIN:%s  VM_IP :%-15s " "$ii" "$RET" "$VM_IP")
                  local thisMSG="${FUNCNAME[0]} dhcp         count"
                  printlog_function_out "${grey}$thisCMD" "$thisMSG"
            done
            QUIET=
      else
            VM_IP=${VM_IP4_STATIC}
      fi
      #wait til up
      isOnline ${VM_IP} 22 'isUP' ${domainName} ${thisLIBVIRTHOST};
      if [[ $isREACHABLE -eq 0 ]] || isVMDOMAINrunning ${domainName} ${thisLIBVIRTHOST}; then
              local thisCMD=$(echo "Domain ${domainName} seems to be online")
              local thisMSG="${FUNCNAME[0]} virsh start " && printlog_function_out "$thisCMD" "$thisMSG"
              export CURRENTSAT=0
      fi
} #EOF startupVMDOMAIN ()


shutdownVM_interactive () {
      local thisVM_DOMAINNAME=$1
      local thisLIBVIRTHOST=$2
      local CMD=$(echo ${thisVM_DOMAINNAME}) && MSG="VM_DOMAINNAME (release)" && printlog_function_in "$CMD" "$MSG"
      if existVMDOMAIN ${thisVM_DOMAINNAME} ${thisLIBVIRTHOST}; then
         if isVMDOMAINrunning ${thisVM_DOMAINNAME} ${thisLIBVIRTHOST}; then
               if isYES "there is a released VM, do you realy want to continue reconfig"; then
                     if isYES "shutdown exitsting released VM now"; then
                           shutdownVMDOMAIN ${thisVM_DOMAINNAME} ${thisLIBVIRTHOST}
                           CURRENTSAT=0
                     else
                           CURRENTSAT=1
                     fi
               else
                     exit 1;
               fi
         else
               export CURRENTSAT=1; fi
      fi
      export CURRENTSAT
      local CMD=$(echo ${CURRENTSAT}) && local MSG="CURRENTSAT" && printlog_function_out "$CMD" "$MSG"
} #EOF shutdownVM_interactive


undefineVM_interactive () {
      local thisVM_DOMAINNAME=$1
      local thisLIBVIRTHOST=$2
      local VM_UNDFINED=0      # 0 - VM defined | 1 - VM undefined
      local CURRENTSAT=0       # 0 - VM running | 1 - VM stopped
      local thisCMD=$(echo ${thisVM_DOMAINNAME}) && thisMSG="VM_DOMAINNAME (release)" && printlog_function_in "$thisCMD" "$thisMSG"
      if existVMDOMAIN ${thisVM_DOMAINNAME} ${thisLIBVIRTHOST}; then
         if isYES "there is a released VM, do you realy want to continue reconfig"; then
               if isVMDOMAINrunning ${thisVM_DOMAINNAME} ${thisLIBVIRTHOST}; then
                     if isYES "VM is up, do you realy want shutdown now"; then
                           CURRENTSAT=0
                           shutdownVMDOMAIN ${thisVM_DOMAINNAME} ${thisLIBVIRTHOST}
                     else
                           CURRENTSAT=1
                           exit 1
                     fi
               else
                     CURRENTSAT=1;
               fi
            else
                  exit 1;
            fi
      else
            VM_UNDFINED=1
      fi
      export VM_UNDFINED
      export CURRENTSAT
      local thisCMD=$(echo ${CURRENTSAT})
      local thisMSG="CURRENTSAT" && printlog "$thisCMD" "$thisMSG"
     # delete old release
      if [ ${CURRENTSAT} -eq 1 ]; then
            if isYES "do you realy want undefine released VM and displace with this kanku-VM" 3600; then
                  echo -n "    undefine: "
                  sudo virsh undefine --domain ${VM_DOMAINNAME} --remove-all-storage
                  VM_UNDFINED=0
            else
                  VM_UNDFINED=1
                  exit 1
            fi
            export VM_UNDFINED
      fi
} #EOF undefineVM_interactive


hkeyMEDICATE () {
   local thisDOMAINNAME=$1
   local thisLIBVIRTHOST=$2
   local thisHOSTKEYFILE=$HOME/.ssh/known_hosts
   # check if domain exists
   if existVMDOMAIN ${thisDOMAINNAME} ${thisLIBVIRTHOST}; then
         # get vm-network to array
         getVMDOMAIN_arr ${thisDOMAINNAME} ${thisLIBVIRTHOST}
         local hisMAC=${DOM_NIF[4]};
         if [ $VM_NETWORK_TYPE == 'dhcp' ]; then
               local hisIP=$(ip neigh | fgrep --no-messages ${DOM_NIF[4]} | cut -d' ' -f1)
         else
               local hisIP=${VM_IP4_STATIC}
         fi
         local hisHOSTKEY_known_hosts=$(ssh-keygen -q -F ${hisIP} | cut -d' ' -f3)
   fi
   local thisCMD=$(echo "${hisMAC}") && local thisMSG="${FUNCNAME[0]} hisMAC" && printlog_function_in "$thisCMD" "$thisMSG"
   local thisCMD=$(echo "${hisIP}") && local thisMSG="${FUNCNAME[0]} hisIP" && printlog_function_in "$thisCMD" "$thisMSG"
   #check hostkey-missmacht
   deleteDOUBBLELINES $thisHOSTKEYFILE
   if [ ! -z ${hisHOSTKEY_known_hosts} ]; then
      local hisALGO_known_hosts=$(ssh-keygen -q -F ${hisIP} | cut -d' ' -f2 | cut -d '-' -f1)
      thisCMD=$(echo ${hisALGO_known_hosts}) && thisMSG="${FUNCNAME[0]} hisALGO_known_hosts" && printlog_function "$thisCMD" "$thisMSG"
      local hisHOSTKEY=$(ssh-keyscan -4 -t $(echo ${hisALGO_known_hosts}) ${hisIP} 2>&1 | fgrep -v '#'| cut -d' ' -f3)
      thisCMD=$(echo ${hisHOSTKEY}) && thisMSG="${FUNCNAME[0]} hisHOSTKEY" && printlog_function "$thisCMD" "$thisMSG"
   fi
   # medicate known_hosts if hostkey-missmacht
   if [ "${hisHOSTKEY_known_hosts}" != "${hisHOSTKEY}" ] && [ ! -z ${hisHOSTKEY_known_hosts} ] ; then
         echo "${dimred} ERROR: KEY-MISSMATCH - REMOVE OLD HOSTKEYS"
         local old_hostkeys=$(mktemp /tmp/old_hostkeys.XXX)
         # old keys to remove:
         cat $thisHOSTKEYFILE | fgrep --no-messages $hisHOSTKEY_known_hosts | tr -s ' ' > $old_hostkeys
         echo "${orange}* ${grey}###- ${dimwhite}\$old_hostkeys${grey} -###"
         echo -n "${dimred}"
         cat -v $old_hostkeys
         echo -n ${reset}
         # fork known_hosts
         thisCMD=$(cp -v $thisHOSTKEYFILE $HOME/.ssh/known_hosts.tmp0) && thisMSG="copy" && printlog_function "$thisCMD" "$thisMSG"
         sed -i "s|$(echo ${hisHOSTKEY_known_hosts})|$(echo ${hisHOSTKEY})|g" $thisHOSTKEYFILE.tmp0
         # backup and create patch
         local SRC=$thisHOSTKEYFILE.tmp0
         local FILE=$thisHOSTKEYFILE
         diff -s "$SRC" "$FILE" >/dev/null
         local DIFF=$(echo $?)
         if [ "$DIFF" == "1" ] || [ "$DIFF" == "2" ]; then
            backup_file $FILE $SRC
            local thisCMD=$(cp -v $SRC $FILE) && local thisMSG="${FUNCNAME[0]} copy" && printlog_function_out "$thisCMD" "$thisMSG"
         fi
         local thisCMD=$(echo $DIFF) && thisMSG="${FUNCNAME[0]} out DIFF" && printlog_function_out "$thisCMD" "$thisMSG"
         rm $thisHOSTKEYFILE.tmp0
   else
         local thisCMD=$(echo "OK")
         local thisMSG="HOSTKEY"
         printlog_function_out "$thisCMD" "$thisMSG"
   fi #Eif [ ${hisHOSTKEY_known_hosts} != ${hisHOSTKEY} ] && [ ! -z ${hisHOSTKEY_known_hosts} ]
} #EOF hkeyMEDICATE ()

#FIN

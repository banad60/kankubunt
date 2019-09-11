#!/bin/bash
# kankubunt - cause it's with kanku ... und bunt too

# usage: isOnline <IP> <Port> <isDOWN|isUP>
isOnline () {
      local thisIP=$1
      local thisPORT=$2
      local search=$3
      local domainName=$4
      local thisLIBVIRTHOST=$5;
      DEBUG=0
      MULTILINE=1
      if [ ! -z $DEBUG ] && [ $DEBUG -gt 0 ]; then
            printlog_function_in "$(echo ${thisIP})" "${FUNCNAME[0]} thisIP"
            printlog_function_in "$(echo ${thisPORT})" "${FUNCNAME[0]} thisPORT"
            printlog_function_in "$(echo ${search})" "${FUNCNAME[0]} search"
            printlog_function_in "$(echo ${domainName})" "${FUNCNAME[0]} domainName"
            printlog_function_in "$(echo ${thisLIBVIRTHOST})" "${FUNCNAME[0]} thisLIBVIRTHOST"
      fi
      # defaults
      DOT=''
      i=1
      x=1
      y=1
      loop=0
      limit=35
      (( countdown = limit ))
      wait_for_loop=
      tmpping=$(mktemp /tmp/tmpping.XXX)
      while true; do
            # special for dhcp
            if [ "$VM_NETWORK_TYPE" == "dhcp" ] && [ -z $VM_IP ]; then
                  if [ ! -z $DEBUG ] && [[ $DEBUG -gt 0 ]]; then
                        printlog_function_in "$(echo ${VM_NETWORK_TYPE})" "${FUNCNAME[0]} dhcp sleep 1 (i=$i)"
                  fi
                  sleep 1
                   # prepare ${VM_IP}
                  VM_IP=
                  getVM_IPfromDOMAIN ${domainName} ${thisLIBVIRTHOST};
                  if [ -z ${VM_IP} ]; then
                        if [ ! -z $DEBUG ] && [[ $DEBUG -gt 0 ]]; then
                              printlog_function_in "$(echo no VM_IP)" "${FUNCNAME[0]} dhcp  VM_IP)"
                        fi
                        i+=1;
                        continue;
                  fi;
            fi
            if [ "$VM_NETWORK_TYPE" == "dhcp" ] && [ -z $VM_IP ]; then
               nc -w1 -vv -z ${VM_IP} $thisPORT > $tmpping 2>&1;
               export isREACHABLE=$?
            else
               nc -w1 -vv -z $thisIP $thisPORT > $tmpping 2>&1;
               export isREACHABLE=$?
            fi
            if [[ $isREACHABLE -eq 0 ]]; then
                  thisCMD=$(echo ${green}${isREACHABLE})
            else
                  thisCMD=$(echo ${red}${isREACHABLE})
            fi
            if [ ! -z $DEBUG ] && [[ $DEBUG -gt 0 ]]; then
                  printlog_function_out "${thisCMD}" "${FUNCNAME[0]} isREACHABLE"
            fi
            # get the result int a var
            ncMSG=$(cat -s $tmpping | cut -d':' -f2 | tr -d '\r' | sed 's/^[ \t]*//;s/[ \t]*$//' | tr -s ' ')
            thisCMD=$(printf "%-6s: ${grey}%s \n" "$i" "$ncMSG" )
            # store last succeeded result
            (( succeeded_last= succeeded ))
            # check succeeded
            echo $ncMSG | fgrep 'succeeded' &>/dev/null
            succeeded=$?
            # count change betwen last ant this result
            if [ $succeeded -eq $succeeded_last ]; then nochange=true; else  nochange=false; fi
            # store last succeeded result
            loop_last=$loop
            #determine loop value
            (( loop = ( i - 1 ) / limit ))
            (( nextloop = loop + 1 ))
            #(( loop = i / limit ))
            if [ $loop -eq $loop_last ]; then loopchange=false; else  loopchange=true; fi
            if [ $nochange == false ]; then (( wait_for_loop = loop + 1 )); fi
            # differenze between odd or even (= forward an backward in the info view)
            if (( $loop % 2 )); then
                  # even loops (limit+1 to 1)
                  #count decrement
                  (( countdown-=1 ))
                  if [ $succeeded -eq 0 ] ; then
                        if [[ $wait_for_loop -eq $nextloop ]] ; then DOT=$(repeatChar $countdown '.'); else DOT=$(repeatChar $countdown '+'); fi
                        DOT2=$(repeatChar $y '+')
                        thisMSG=${grey}$DOT${dimgreen}$DOT2 ;
                  else
                        if [[ $wait_for_loop -eq $nextloop ]] ; then DOT=$(repeatChar $countdown '.'); else DOT=$(repeatChar $countdown '-'); fi
                        DOT2=$(repeatChar $y '-')
                        thisMSG=${grey}$DOT${dimred}$DOT2 ;
                  fi
                  if [ $y -eq $limit ] ; then
                      thisMSG=$DOT${blutorange}$DOT2 ;
                  fi
                  #count increment
                  (( y+=1 ))
                  #reset
                  x=1
            else
                  # odd loops (1 to limit+1 )
                  #count decrement
                  (( countdown2 = limit - x ))
                  if [ $succeeded -eq 0 ] ; then
                        DOT=$(repeatChar $x '+')
                        if [[ $wait_for_loop -eq $nextloop ]] ; then DOT2=$(repeatChar $countdown2 '.'); else DOT2=$(repeatChar $countdown2 '+'); fi
                        thisMSG=${dimgreen}$DOT${grey}$DOT2;
                  else
                        DOT=$(repeatChar $x '-')
                        if [[ $wait_for_loop -eq $nextloop ]] ; then DOT2=$(repeatChar $countdown2 '.'); else DOT2=$(repeatChar $countdown2 '-'); fi
                        thisMSG=${dimred}$DOT${grey}$DOT2;
                  fi
                  if [ $x -eq $limit ] ; then
                      DOT2=''
                      thisMSG=${blutorange}$DOT
                  fi
                  #count increment
                  (( x+=1 ))
                  # reset
                  y=1
                  (( countdown = limit ))
            fi
            # output
            logStamp
            if [ ! -z $MULTILINE ] && [[ $MULTILINE -gt 0 ]]; then thisCLF1="\n"; thisCLF2="\n"; else thisCLF1="\r"; thisCLF2="\r"; fi
            if [ ! -z $DEBUG ] && [[ $DEBUG -gt 0 ]]; then thisCLF1=''; fi
            if [[ $succeeded -eq 0 ]] ; then
                  printf "${dimyellow}%s ${dimgreen}%-35s: ${babyblue}%s$thisCLF1" "${LOGSTAMP}" "$thisMSG" "$thisCMD" ;
            else
                  printf "${dimyellow}%s ${dimred}%-35s: ${babyblue}%s$thisCLF1" "${LOGSTAMP}" "$thisMSG" "$thisCMD" ;
            fi
            if [ ! -z $DEBUG ] && [[ $DEBUG -gt 0 ]]; then
               printf "${dimwhite}loop:%s loopchange:%s i:%s cntdwn:%-2s x:%-2s cntdwn2:%-2s y:%-2s succeeded:%s nochange:%s wait_for_loop:%s${reset}$thisCLF2" "$loop" "$loopchange" "$i" "$countdown" "$x" "$countdown2" "$y" "$succeeded" "$nochange" "$wait_for_loop";
            fi
            #count increment
            (( i+=1 ))
            sleep 1
            # kickout
            case $search in
                  isDOWN)
                     if [ $succeeded -eq 1 ] ; then
                           break
                     fi
                  ;;
                  isUP|*)
                     if [ $succeeded -eq 0 ] ; then
                           break
                     fi
                  ;;
            esac
      done
      rm $tmpping
      if [[ $isREACHABLE -eq 0 ]]; then
            printlog_function_out "$(echo 0)" "${FUNCNAME[0]} return"
            return 0
      else
            printlog_function_out "$(echo 1)" "${FUNCNAME[0]} return"
            return 1
      fi
} #Eof isOnline ()

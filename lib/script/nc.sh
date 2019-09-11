#!/bin/bash
# kankubunt - cause it's with kanku ... und bunt too

# kick out
if [ -z $1 ] || [ -z $2 ]; then echo "usage: $0 {option: --oneline --debug} <host> <port>"; exit 1; fi
# get the lbrary, if non present
if [ -z ${TIMESTAMP} ]; then
   inLIBDIR=$(pwd|rev|cut -d'/' -f1|rev);
   if [ ${inLIBDIR} != 'lib' ]; then
      . lib/helper.sh
   else
      . helper.sh
   fi
fi
# manage input
args=$#
if [[ $args -eq 3 ]]; then
      case $1 in
         --oneline)
               DEBUG=0
               MULTILINE=0
         ;;
         --debug)
               DEBUG=1
               MULTILINE=1
         ;;
      esac
      HOST=$2
      PORT=$3
      if [[ $DEBUG -gt 0 ]]; then
            printf "${dimyellow}args:\n${grey} 1: %s\n 2: %s\n 3: %s\n"  "$1" "$2" "$3";
            echo -n ${reset};
      fi
elif [[ $args -eq 4 ]]; then
      DEBUG=1
      MULTILINE=0
      HOST=$3
      PORT=$4
      printf "${dimyellow}args:\n${grey} 1: %s\n 2: %s\n 3: %s\n 4: %s\n"  "$1" "$2" "$3" "$4"
      echo -n ${reset};
else
      DEBUG=0
      MULTILINE=1
      HOST=$1
      PORT=$2
fi
# defaults
DOT=''
i=1
x=1
y=1
loop=0
limit=30
(( countdown = limit ))
wait_for_loop=
tmpping=$(mktemp /tmp/tmpping.XXX)
## actione
while true; do
      # fetch wit netcat
      nc -w1 -vv -z $HOST $PORT > $tmpping 2>&1;
      export isREACHABLE=$?
      # get the result int a var
      ncMSG=$(cat -s $tmpping | cut -d':' -f2 | tr -d '\r' | sed 's/^[ \t]*//;s/[ \t]*$//' | tr -s ' ')
      thisCMD=$(printf "%6s ${grey}%s \n" "$i" "$ncMSG" )
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
      if [ ! -z $DEBUG ] && [[ $DEBUG -gt 0 ]]; then thisCLF1=""; fi
      if [[ $succeeded -eq 0 ]] ; then
            printf "${dimyellow}%s ${dimgreen}%-30s: ${babyblue}%s$thisCLF1" "${LOGSTAMP}" "$thisMSG" "$thisCMD" ;
      else
            printf "${dimyellow}%s ${dimred}%-30s: ${babyblue}%s$thisCLF1" "${LOGSTAMP}" "$thisMSG" "$thisCMD" ;
      fi
      if [ ! -z $DEBUG ] && [ $DEBUG -gt 0 ]; then
         printf "${dimwhite}loop:%-4s loopchange:%s i:%-4s cntdwn:%-2s x:%-2s cntdwn2:%-2s y:%-2s succeeded:%s nochange:%s wait_for_loop:%s${reset}$thisCLF2" "$loop" "$loopchange" "$i" "$countdown" "$x" "$countdown2" "$y" "$succeeded" "$nochange" "$wait_for_loop";
      fi
      #count increment
      (( i+=1 ))
      sleep 1
done
rm $tmpping

#FIN

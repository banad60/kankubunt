#!/bin/bash
# kankubunt - cause it's with kanku ... und bunt too

# get the lbrary, if non present
if [ -z ${TIMESTAMP} ]; then
   inLIBDIR=$(pwd|rev|cut -d'/' -f1|rev);
   if [ ${inLIBDIR} != 'lib' ]; then
      . lib/helper.sh
   else
      . helper.sh
   fi
fi
titleheader 'install local-kanku-source' ${dimblue};

# get uri of ini & insert inifile
if [ -L "configs/KankuFile.ini" ]; then
       INIFILE_fullpath=$(readlink -f configs/KankuFile.ini)
       INIFILE="${INIFILE_fullpath##*/}";
else
      INIFILE='KankuFile_dhcp-default.ini'
fi

# insert inifile
CMD=$(echo ${INIFILE}) && MSG="INIFILE" && printlog "$CMD" "$MSG"

# read defaults
IMAGENAME=$(cat configs/defaults/${INIFILE}|fgrep VM_IMAGENAME |sed 's/VM_IMAGENAME=//g'|cut -d "'" -f2)
CMD=$(echo ${IMAGENAME}) && MSG="IMAGENAME" && printlog "$CMD" "$MSG"
DOMAIN=$(cat configs/defaults/${INIFILE}|fgrep VM_DOMAINNAME |sed 's/VM_DOMAINNAME=//g'|cut -d "'" -f2)
CMD=$(echo ${DOMAIN}) && MSG="DOMAIN" && printlog "$CMD" "$MSG"

# local storage path
IMGAGEPATH=${HOME}/.cache/kanku
CMD=$(echo ${IMGAGEPATH}) && MSG="IMGAGEPATH" && printlog "$CMD" "$MSG"

##first check the source
callRECONFIG=
if fileExist ${IMGAGEPATH}"/"${IMAGENAME}".qcow2"; then

      CMD=$(echo ${IMGAGEPATH}"/"${IMAGENAME}".qcow2 exist - reconfig kanku" ) && MSG="fileExist" && printlog_result "$CMD" "$MSG"
      callRECONFIG=true

      if isYES "An ubuntu image is installed already! Do you realy want reinstall?" 10; then
            # an  do do realy?
          #. lib/reconfig-kankuVM.sh $*
          . lib/reconfig-kankuVM.sh $*
          if [ ! -z ${thisIP} ]; then
             titleheader 'del old ssh hostkey' ${orange};
             echo -n ${orange};
             ssh-keygen -R ${thisIP} -f $HOME/.ssh/known_hosts
             echo -n ${reset};
          fi
      else
           exit 1
      fi

else
    CMD=$(echo ${IMGAGEPATH}"/"${IMAGENAME}".qcow2 don't exist - install it" ) && MSG="fileExist" && printlog "$CMD" "$MSG"
fi
export callRECONFIG

#reset inifile to default
backup_file configs/${INIFILE} configs/defaults/${INIFILE}
CMD=$(cp -v configs/defaults/${INIFILE} configs/${INIFILE}) && MSG="copy" && printlog "$CMD" "$MSG"

. lib/createVM_serial-only_preseeded_us_v0.2.sh

# switch first install or not
if [ -z $callRECONFIG ]; then
       export callRECONFIG=true
       . lib/reconfig-kankuVM.sh dhcp-default
fi

titleheader 'kanku up' ${green};
kanku up;

# terminal reset
resize >/dev/null

# terminal reset
. lib/fork-local-kanku-source.sh

exit 0

#FIN


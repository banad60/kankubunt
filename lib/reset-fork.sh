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

MSG=" ERROR: no KankuFile"
if [ ! -f "KankuFile" ]; then
      echo ${dimred}${MSG}${reset}
      exit 1
else
      export TIMESTAMP
      export VM_KANKUPREFIX="kanku"

      titleheader 'reset fork' ${brown};

      # insert inifile
      if [ -L "configs/KankuFile.ini" ]; then
            INIFILE_fullpath=$(readlink -f configs/KankuFile.ini)
            INIFILE="${INIFILE_fullpath##*/}";
      else
            INIFILE='KankuFile_dhcp-default.ini'
      fi
      . configs/${INIFILE}

      if [ -z ${VM_IMAGE_REV} ] || [ ${VM_IMAGE_REV} -eq 0 ]; then
            echo " ${dimred} this is revision 0 - minimal revision for a reset is revision 1"${reset}
            exit 1
      else
            CMD=$(echo ${INIFILE}) && MSG="INIFILE" && printlog "$CMD" "$MSG"
      fi

      DOMAIN=$(cat KankuFile|fgrep domain_name|sed 's/^[ \t]*//'|cut -d' ' -f2)
      CMD=$(echo ${DOMAIN}) && MSG="DOMAIN" && printlog "$CMD" "$MSG"

      # shutdown source-image, if running
      if isVMDOMAINrunning ${DOMAIN}; then
            CMD=$(sudo virsh destroy --domain ${DOMAIN}) && MSG="virsh destroy" && printlog "$CMD" "$MSG"
      fi

      # get IMGAGEPATH from KankuFile
      IMGAGEPATH=$(cat KankuFile|fgrep cache_dir|sed 's/^[ \t]*//'|cut -d' ' -f2)
      CMD=$(echo ${IMGAGEPATH}) && MSG="IMGAGEPATH" && printlog "$CMD" "$MSG"

      # get REVIMAGENAME from KankuFile
      REVIMAGENAME=$(cat KankuFile|fgrep vm_image_file|sed 's/^[ \t]*//'|cut -d' ' -f2 | cut -d'.' -f1 )
      CMD=$(echo ${REVIMAGENAME}) && MSG="REVIMAGENAME" && printlog "$CMD" "$MSG"

      # get REVNAME from KankuFile
      REVNAME=$(cat KankuFile|fgrep vm_image_file|sed 's/^[ \t]*//'|cut -d' ' -f2 | cut -d'.' -f1 | cut -d'_' -f1-2)
      CMD=$(echo ${REVNAME}) && MSG="REVNAME" && printlog "$CMD" "$MSG"

      # remove all revisions-images
      if fileExist ${IMGAGEPATH}/${REVIMAGENAME}".qcow2"; then
            CMD=$(rm -vf ${IMGAGEPATH}/${REVNAME}_* | sed "s/'/\"/g" | cut -d ' ' -f1 | sed 's/"//g' | sed ':a; N; s/\n/, /; ta')
            MSG="remove" && printlog "$CMD" "$MSG"
      else
            CMD=$(echo "no ${REVNAME}_* images - nothing to do!") && MSG="remove" && printlog "$CMD" "$MSG"
      fi

      # remove Kankufile
      if fileExist 'KankuFile'; then
            CMD=$(rm -vf KankuFile) && MSG="remove" && printlog "$CMD" "$MSG"
      else
            CMD=$(echo "no 'KankuFile' - nothing to do!") && MSG="remove" && printlog "$CMD" "$MSG"
      fi

      # shutdown source-image, if running
      if existVMDOMAIN ${DOMAIN}; then
            CMD=$(sudo virsh undefine --domain ${DOMAIN} --remove-all-storage) && MSG="virsh undefine" && printlog "$CMD" "$MSG"
            wait
      fi

      # reset INIFILE
      CMD=$(cp -Pv configs/defaults/${INIFILE} configs/${INIFILE}) && MSG="reset INIFILE" && printlog "$CMD" "$MSG"
      . configs/KankuFile.ini

      CMD=$(echo ${VM_IMAGENAME}) && MSG="VM_IMAGENAME" && printlog "$CMD" "$MSG"
      CMD=$(echo ${VM_IMAGE_REV}) && MSG="VM_IMAGE_REV" && printlog "$CMD" "$MSG"
      export VM_IMAGE_REV=
      #VM_IMAGEFILE=

      #render new netplan, .tt2 and KankuFile
      . lib/render-template.sh

      CMD=$(echo ${VM_IMAGEFILE}) && MSG="VM_IMAGEFILE" && printlog "$CMD" "$MSG"

      titleheader 'kanku up' ${green};
      kanku up;
      # terminal reset
      resize >/dev/null

      CMD=$(echo ${VM_IMAGEFILE}) && MSG="VM_IMAGEFILE" && printlog "$CMD" "$MSG"

      # go to revison 1
      . lib/fork-local-kanku-source.sh

      echo ${dimgreen}
      echo "                            now can login over : ${dimyellow}ssh -A root@${VM_IP}${dimgreen}"
      echo "          or edit the KankuFile before execute : ${dimyellow}./revision-kanku-vm${dimgreen}"
      echo "                                    or execute : ${dimyellow}./release-kanku-vm${dimgreen}"
      echo "                     or reconfigure this setup : ${dimyellow}./reconf-kanku-vm <option>"
      echo  ${reset}

fi; #Eif [ ! -f "KankuFile" ]

exit 0


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

      titleheader 'release fork' ${seegreen};

      # get uri of ini & insert inifile
      if [ -L "configs/KankuFile.ini" ]; then
             INIFILE_fullpath=$(readlink -f configs/KankuFile.ini)
             INIFILE="${INIFILE_fullpath##*/}";
      else
            INIFILE='KankuFile_dhcp-default.ini'
      fi
      . configs/${INIFILE}

     # check revision
      if [ ! -z $VM_IMAGE_REV ]; then
            tmp=$(mktemp /tmp/tmp.XXX)
            cat KankuFile|fgrep vm_image_file|sed 's/^[ \t]*//'|cut -d' ' -f2 | cut -d'.' -f1|cut -d'_' -f3 > $tmp
            sed -i "s/r//g" $tmp
            REV=$(cat $tmp)
            rm $tmp
      else
            REV=0
      fi
      #
      if [[ $REV -gt 0 ]] ; then
         #echo "    REV="${REV}
         CMD=$(echo "${REV}") && MSG="REV" && printlog_result "$CMD" "$MSG"
      else
         CMD=$(echo "${REV} ${ARROW_R} ${dimred}is to low! for releasing minimum is 1.") && MSG="REV" && printlog_result "$CMD" "$MSG"
         exit 1
      fi

      #- define some vars -#
      DOMAIN=$(cat KankuFile|fgrep domain_name|sed 's/^[ \t]*//'|cut -d' ' -f2)
      CMD=$(echo "${DOMAIN}") && MSG="DOMAIN" && printlog "$CMD" "$MSG"

      # do this, if domain exists
      if existVMDOMAIN ${DOMAIN} ${LIBVIRTHOST}; then

            CMD=$(echo ${VM_NETWORK_TYPE}) && MSG="VM_NETWORK_TYPE" && printlog "$CMD" "$MSG"

            if [ "${VM_NETWORK_TYPE}" == 'dhcp' ]; then
               if ! isVMDOMAINrunning ${DOMAIN} ${LIBVIRTHOST}; then
                  if isYES "with dhcp it is needed, that the VM is runnning yet" 3600; then
                     startupVMDOMAIN ${DOMAIN} ${LIBVIRTHOST};
                  fi
               fi
            fi


            # shutdown released-image, if running (interactiv)
            undefineVM_interactive ${VM_DOMAINNAME} ${LIBVIRTHOST}

            #IMAGENAME=u1804us
            if [ -z ${VM_IMAGE_REV} ]; then
                  IMAGENAME=$(cat KankuFile|fgrep vm_image_file|sed 's/^[ \t]*//'|cut -d' ' -f2 | cut -d'.' -f1)
            else
                  IMAGENAME=$(cat KankuFile|fgrep vm_image_file|sed 's/^[ \t]*//'|cut -d' ' -f2 | cut -d'.' -f1 | cut -d'_' -f1)
            fi
            CMD=$(echo "${IMAGENAME}") && MSG="IMAGENAME" && printlog "$CMD" "$MSG"

            # compute release-candidate
            _RC_IMG_VER="1.00-"${VM_IMAGE_REV}
             CMD=$(echo "${_RC_IMG_VER}") && MSG="_RC_IMG_VER" && printlog "$CMD" "$MSG"

            #get cache_dir
            IMGAGEPATH=$(cat KankuFile|fgrep cache_dir|sed 's/^[ \t]*//'|cut -d' ' -f2)
            CMD=$(echo "${IMGAGEPATH}") && MSG="IMGAGEPATH" && printlog "$CMD" "$MSG"

            IMGAGEPATH_libvirt=/var/lib/libvirt/images
            CMD=$(echo "${IMGAGEPATH_libvirt}") && MSG="IMGAGEPATH_libvirt" && printlog "$CMD" "$MSG"


            if [ "${VM_NETWORK_TYPE}" == 'static' ]; then
               if ! isVMDOMAINrunning ${DOMAIN} ${LIBVIRTHOST}; then
                  #if isYES "with dhcp it is needed, that the VM is runnning yet" 3600; then
                     startupVMDOMAIN ${DOMAIN} ${LIBVIRTHOST};
                  #fi
               fi
            fi

            # select between dhcp|static
            CMD=$(echo ${VM_NETWORK_TYPE}) && MSG="VM_NETWORK_TYPE" && printlog "$CMD" "$MSG"
            if [ "${VM_NETWORK_TYPE}" == 'static' ]; then
                  CMD=$(echo ${VM_IP4_STATIC}) && MSG="VM_IP4_STATIC" && printlog "$CMD" "$MSG"
                  VM_IP=${VM_IP4_STATIC}
            else
                  #dhcp
                  # get vm-network to array
                  getVMDOMAIN_arr ${DOMAIN} ${LIBVIRTHOST}
                  getVM_IPfromDOMAIN ${DOMAIN} ${LIBVIRTHOST}
            fi #Eif [ "${VM_NETWORK_TYPE}" == 'static' ]

            #get ip, if the VM is up
            if [ ! -z "$VM_IP" ]; then
               #echo "  VM_IP="${VM_IP}
               CMD=$(echo ${VM_IP}) && MSG="VM_IP" && printlog "$CMD" "$MSG"
               export VM_IP
            else
               echo "${red}ERROR: no VM_IP yet!! may ${DOMAIN} be down?"
               echo "${dimred} try \"sudo virsh start ${DOMAIN}\" and execute \"$0\" again${reset}"
               exit 1
            fi

            #start up again, if down
            if ! isVMDOMAINrunning ${DOMAIN} ${LIBVIRTHOST}; then
                  startupVMDOMAIN ${DOMAIN} ${LIBVIRTHOST};
            fi

            # before this, clear some things out
            hkeyMEDICATE ${DOMAIN} ${LIBVIRTHOST}

            # prepare ssh command an execute ir
            sshCMD="systemctl disable mount-kanku-tmp.service && systemctl stop mount-kanku-tmp.service ; \
                                sed -i.bak '/kankushare/d' /etc/fstab ; \
                                grub-mkconfig -o /boot/grub/grub.cfg && update-grub;"
            echo -n ${orange};
            ssh -o "StrictHostKeyChecking no" -A root@${VM_IP} -t ${sshCMD}
            echo -n ${reset};

            # shutdown source-image, if running
            CMD=$(sudo virsh destroy --domain ${DOMAIN}) && MSG="virsh destroy" && printlog "$CMD" "$MSG"

            # compute the names
            _REVISION_NAME=$(cat KankuFile|fgrep vm_image_file|sed 's/^[ \t]*//'|cut -d' ' -f2 | cut -d'.' -f1 | cut -d'_' -f1-2)
            CMD=$(echo ${_REVISION_NAME}) && MSG="_REVISION_NAME" && printlog "$CMD" "$MSG"

            _RELEASED_NAME=$(cat KankuFile|fgrep vm_image_file|sed 's/^[ \t]*//'|cut -d' ' -f2 | cut -d'.' -f1 | cut -d'_' -f2)
            CMD=$(echo ${_RELEASED_NAME}) && MSG="_RELEASED_NAME" && printlog "$CMD" "$MSG"

            # prepare image
            operations=$(virt-sysprep --list-operations | egrep -v 'fs-uuids|lvm-uuids|ssh-userdir|ssh-hostkeys' | awk '{ printf "%s,", $1}' | sed 's/,$//')
            CMD=$(echo $operations) && MSG="virt-sysprep" && printlog "$CMD" "$MSG"

            # prepare the release
            sudo virt-sysprep -d "${DOMAIN}" --hostname "${_RELEASED_NAME}" \
                                             --keep-user-accounts root \
                                             --root-password password:DoLegstDiNidaUndStehstNimmaAuf \
                                             --remove-user-accounts kanku \
                                             --enable $operations

            # convert
            CMD=$(echo ${IMGAGEPATH_libvirt}"/"${DOMAIN}".qcow2 to "${IMGAGEPATH_libvirt}"/"${_RELEASED_NAME}"_"${_RC_IMG_VER}".qcow2") && MSG="qemu-img convert" && printlog "$CMD" "$MSG"
            echo -n ${orange};
            sudo qemu-img convert -p ${IMGAGEPATH_libvirt}/${DOMAIN}.qcow2 -O qcow2 ${IMGAGEPATH_libvirt}/${_RELEASED_NAME}"_"${_RC_IMG_VER}.qcow2
            echo -n ${reset};

            tmp=$(mktemp /tmp/tmp.XXX)

            # header
            echo "<!-- " >$tmp
            echo "INFO: THIS IS AN AUTO-GENERATED VM release over kankubunt" >>$tmp
            echo "-->" >>$tmp

            # fetch dump
            sudo virsh dumpxml ${DOMAIN}  >>$tmp

            # change release-name
            sed -i "s/<name>`echo ${DOMAIN}`<\/name>/<name>`echo ${_RELEASED_NAME}`<\/name>/g" ${tmp}

            _RELEASE_IMAGEMNAME=${_RELEASED_NAME}"_"${_RC_IMG_VER}
            CMD=$(echo ${_RELEASE_IMAGEMNAME}) && MSG="_RELEASE_IMAGEMNAME" && printlog "$CMD" "$MSG"
            sed -i "s/`echo ${DOMAIN}.qcow2`/`echo ${_RELEASE_IMAGEMNAME}.qcow2`/g" ${tmp}

            # get rid of kankushare
            cat $tmp | fgrep -v "$(sed -n '/<filesystem/{:x N;/<\/filesystem/!b x};/kankushare/p' ${tmp})" > $tmp
            echo "${orange}*${grey} ---${dimwhite} dumpxml tmp.xml${grey} :"      # view for debug
            cat $tmp                     # view for debug
            echo -n "${reset}"              # view for debug

            # undfine kanku-revision
            CMD=$(sudo virsh undefine --domain ${DOMAIN} --remove-all-storage && wait) && MSG="undefine" && printlog "$CMD" "$MSG"

            #restore VM HW
            CMD=$(sudo cp -Pv $tmp /etc/libvirt/qemu/${_RELEASED_NAME}.xml && wait && rm $tmp) && MSG="copy" && printlog "$CMD" "$MSG"
            CMD=$(sudo chown -v root:root /etc/libvirt/qemu/${_RELEASED_NAME}.xml && wait) && MSG="chown" && printlog "$CMD" "$MSG"

            # define & start new release
            CMD=$(sudo virsh define /etc/libvirt/qemu/${_RELEASED_NAME}.xml)
            MSG="virsh define ${_RELEASED_NAME}"
            printlog "$CMD" "$MSG"

            #& start new release
            startupVMDOMAIN ${_RELEASED_NAME} ${LIBVIRTHOST};

            ##### delete old shith

            # remove all kanku-revisions-images
            if fileExist ${IMGAGEPATH}/${_REVISION_NAME}"_r"${REV}".qcow2"; then
                  #echo -n " *  remove: "
                  CMD=$(rm -vf ${IMGAGEPATH}/${_REVISION_NAME}_* | sed "s/'/\"/g" | cut -d ' ' -f1 | sed 's/"//g' | sed ':a; N; s/\n/, /; ta')
                  MSG="remove" && printlog "$CMD" "$MSG"
            else
                  CMD=$(echo "no ${_REVISION_NAME}_* images - nothing to do!")
                  MSG="remove" && printlog "$CMD" "$MSG"
            fi

            #reset inifile to default
#            CMD=$(cp -v configs/defaults/${INIFILE} configs/${INIFILE}) && MSG="copy" && printlog "$CMD" "$MSG"

            # backup old KakuFile and replace it with a second template
            _OLD_IMAGENAME=${IMAGENAME}"_"${VM_DOMAINNAME}"_1.00-"${VM_IMAGE_REV}
            _DOM_DIRNAME=${IMAGENAME}"_"${VM_DOMAINNAME}

            CMD=$(mkdir -pv KankuFiles/${_DOM_DIRNAME}) && MSG="mkdir" && printlog "$CMD" "$MSG"

            CMD=$(mv -fv KankuFile KankuFiles/${_DOM_DIRNAME}/"_"${TIMESTAMP}"_"KankuFile"_"${_OLD_IMAGENAME}.yml) && MSG="move" && printlog "$CMD" "$MSG"

            logStamp && printf "${dimgreen}%s\n" "${LOGSTAMP}"

            CMD=$(echo "${bold}${white}${_RELEASED_NAME}") && MSG="domain" && printlog "$CMD" "$MSG"

            CMD=$(echo "${bold}${white}${VM_IP}") && MSG="ipaddress" && printlog "$CMD" "$MSG"

            CMD=$(echo "${bold}${white}DoLegstDiNidaUndStehstNimmaAuf")  && MSG="initial root-passwort" && printlog "$CMD" "$MSG"

            CMD=$(echo ${grey}"(do not change, if you wanna be hacked definitely!)") && MSG=" " && printlog "$CMD" "$MSG"

            echo "${reset}"

            echo ${dimgreen}
            echo "                                     ssh login : ${dimyellow}ssh -A root@${VM_IP}${dimgreen}"
            echo ""
            echo "                     or reconfigure this setup : ${dimyellow}./reconf-kanku-vm <option>"
            echo  ${reset}


      else
            # if no domain exists
            CMD=$(echo "domainname ${DOMAIN} did not exist - release impossible") && MSG="ERROR"  && printlog_result_err "$CMD" "$MSG"
      fi #Eif existVMDOMAIN {${DOMAIN}};

fi; #Eif [ ! -f "KankuFile" ]

exit 0


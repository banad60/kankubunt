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

      titleheader 'fork kanku source' ${babyblue};

      # get inifile
      INIFILE_fullpath=$(readlink -f configs/KankuFile.ini)
      . ${INIFILE_fullpath}

      INIFILE="${INIFILE_fullpath##*/}";
      CMD=$(echo ${INIFILE}) && MSG="INIFILE" && printlog "$CMD" "$MSG"

      DOMAIN=$(cat KankuFile|fgrep domain_name|sed 's/^[ \t]*//'|cut -d' ' -f2)
      CMD=$(echo ${DOMAIN}) && MSG="DOMAIN" && printlog "$CMD" "$MSG"

      IMAGENAME=$(cat KankuFile|fgrep vm_image_file|sed 's/^[ \t]*//'|cut -d' ' -f2 | cut -d'.' -f1)
      CMD=$(echo ${IMAGENAME}) && MSG="IMAGENAME" && printlog "$CMD" "$MSG"

      IMGAGEPATH=$(cat KankuFile|fgrep cache_dir|sed 's/^[ \t]*//'|cut -d' ' -f2)
      CMD=$(echo ${IMGAGEPATH}) && MSG="IMGAGEPATH" && printlog "$CMD" "$MSG"

      IMGAGEPATH_libvirt=/var/lib/libvirt/images
      CMD=$(echo ${IMGAGEPATH_libvirt}) && MSG="IMGAGEPATH_libvirt" && printlog "$CMD" "$MSG"

      if ! isVMDOMAINrunning ${DOMAIN} ${LIBVIRTHOST}; then
            startupVMDOMAIN ${DOMAIN} ${LIBVIRTHOST};
      fi

      # select between dhcp|static
      CMD=$(echo ${VM_NETWORK_TYPE}) && MSG="VM_NETWORK_TYPE" && printlog "$CMD" "$MSG"
      if [ "${VM_NETWORK_TYPE}" == 'static' ]; then
            CMD=$(echo ${VM_IP4_STATIC}) && MSG="VM_IP4_STATIC" && printlog "$CMD" "$MSG"
            VM_IP=${VM_IP4_STATIC}
      else
            #dhcp
            getVM_IPfromDOMAIN ${DOMAIN} ${LIBVIRTHOST}
      fi

      CMD=$(echo ${VM_IP}) && MSG="VM_IP" && printlog "$CMD" "$MSG"
      if [ ! -z "$VM_IP" ]; then
         export VM_IP
      else
         startupVMDOMAIN ${DOMAIN} ${LIBVIRTHOST}
      fi

      #check hostkey-missmacht
      hkeyMEDICATE ${DOMAIN} ${LIBVIRTHOST}

      # shutdown source-image, if running
      if isVMDOMAINrunning ${DOMAIN} ${LIBVIRTHOST}; then

            # disable mount-kanku-tmp.service
            # prevent doubble entrys in /etc/fstab
            # update-grub
            sshCMD="systemctl disable mount-kanku-tmp.service && systemctl stop mount-kanku-tmp.service ; \
                    sed -i.bak '/kankushare/d' /etc/fstab ; \
                    grub-mkconfig -o /boot/grub/grub.cfg && update-grub;"
            #exec
            echo -n ${orange};
            ssh -o "StrictHostKeyChecking no" -A root@${VM_IP} -t ${sshCMD}
            echo -n ${reset};

            CMD=$(sudo virsh destroy --domain ${DOMAIN})
            MSG="destroy domain ${DOMAIN}" && printlog "$CMD" "$MSG"
      fi

      ###############################################################
      # with static or dhcp/mac IPs a dubbles can happen, therefor is better to shut off now
      if [ "${VM_NETWORK_TYPE}" == 'static' ] || ([ ${VM_NETWORK_TYPE} == 'dhcp' ] && [ ! -z ${VM_MAC} ]); then
            # delete old release ??
            if isVMDOMAINrunning ${VM_DOMAINNAME} ${LIBVIRTHOST}; then
               CMD=$(sudo virsh destroy --domain ${VM_DOMAINNAME})
               MSG="virsh destroy stop" && printlog "$CMD" "$MSG"
            fi
      fi

      CMD=$(echo ${VM_IMAGE_REV}) && MSG="VM_IMAGE_REV" && printlog "$CMD" "$MSG"
      if [ ! -z ${VM_IMAGE_REV} ]; then
            VM_IMAGE_REV_OLD=${VM_IMAGE_REV}
            ((VM_IMAGE_REV+=1));
            sed -i "s/VM_IMAGE_REV=.*$/`echo VM_IMAGE_REV=${VM_IMAGE_REV}`/g" ${INIFILE_fullpath} ;
      else
            VM_IMAGE_REV=1
            VM_IMAGE_REV_OLD=0
            addFIRSTLINE "\nVM_IMAGE_REV="${VM_IMAGE_REV}  ${INIFILE_fullpath}
      fi
      export VM_IMAGE_REV VM_IMAGE_REV_OLD

      IMAGENAME=$(cat KankuFile|fgrep vm_image_file|sed 's/^[ \t]*//'|cut -d' ' -f2 | cut -d'.' -f1 | cut -d'_' -f1)

      # convert new source
      _NEW_IMAGENAME=${IMAGENAME}"_"${VM_DOMAINNAME}"_r"${VM_IMAGE_REV}
      CMD=$(echo "${IMGAGEPATH_libvirt}/${DOMAIN}.qcow2 to ${IMGAGEPATH}/${_NEW_IMAGENAME}.qcow2")
      MSG="qemu-img convert" && printlog "$CMD" "$MSG"
      echo -n "${blutorange}"
      sudo qemu-img convert -p ${IMGAGEPATH_libvirt}/${DOMAIN}.qcow2 -O qcow2 ${IMGAGEPATH}/${_NEW_IMAGENAME}.qcow2
      echo "${reset}"

      # ubdate ini
      VM_IMAGENAME=${_NEW_IMAGENAME};
      sed -i "s/VM_IMAGENAME=.*$/`echo VM_IMAGENAME=\'${_NEW_IMAGENAME}\'`/g" ${INIFILE_fullpath} ;

      titleheader 'kanku destroy' ${red};
      kanku destroy;
      titleheader 'fork kanku-source' ${grey};

      # backup old KakuFile and replace it with a second template
      _OLD_IMAGENAME=${IMAGENAME}"_"${VM_DOMAINNAME}"_r"${VM_IMAGE_REV_OLD}
      _DOM_DIRNAME=${IMAGENAME}"_"${VM_DOMAINNAME}

      CMD=$(mkdir -pv KankuFiles/${_DOM_DIRNAME})
      MSG="mkdir" && printlog "$CMD" "$MSG"

      CMD=$(mv -v KankuFile KankuFiles/${_DOM_DIRNAME}/"_"${TIMESTAMP}"_"KankuFile"_"${_OLD_IMAGENAME}.yml)
      MSG="move" && printlog "$CMD" "$MSG"

      #render new netplan, .tt2 and KankuFile
      . lib/render-template.sh

      titleheader 'kanku up' ${green};
      kanku up;

      # terminal reset
      resize >/dev/null
fi

#FIN

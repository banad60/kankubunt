#!/bin/bash
# kankubunt - cause it's with kanku ... und bunt too

IMAGENAME=u1804us
DOMAIN=localdomain

IMGAGESIZE=5

# terminal reset
resize >/dev/null

IMGAGEPATH=$HOME/.cache/kanku

# get the lbrary, if non present
if [ -z ${TIMESTAMP} ]; then
   inLIBDIR=$(pwd|rev|cut -d'/' -f1|rev);
   if [ ${inLIBDIR} != 'lib' ]; then
      . lib/helper.sh
   else
      . helper.sh
   fi
fi

titleheader 'define kanku-source VM' ${marineblue};

#get uri of ini
if [ -L "configs/KankuFile.ini" ]; then
      INIFILE_fullpath=$(readlink -f configs/KankuFile.ini)
      INIFILE="${INIFILE_fullpath##*/}";
else
      INIFILE='KankuFile_dhcp-default.ini'
fi

# get from inifile
LIBVIRTHOST=$(cat configs/${INIFILE}|fgrep LIBVIRTHOST |sed 's/LIBVIRTHOST=//g'|cut -d "'" -f2)
CMD=$(echo ${LIBVIRTHOST}) && MSG="LIBVIRTHOST" && printlog "$CMD" "$MSG"

VM_NETWORK_TYPE=$(cat configs/${INIFILE}|fgrep VM_NETWORK_TYPE |sed 's/VM_NETWORK_TYPE=//g'|cut -d "'" -f2)
CMD=$(echo ${VM_NETWORK_TYPE}) && MSG="VM_NETWORK_TYPE" && printlog "$CMD" "$MSG"

if fileExist ${IMGAGEPATH}/${IMAGENAME}".qcow2"; then
      # shutdown source-image, if running
      if existVMDOMAIN ${IMAGENAME}; then
         if isYES "there exist a VM with source image \"${IMAGENAME}\", do you want renew it"; then
            if isVMDOMAINrunning ${IMAGENAME} ${LIBVIRTHOST}; then
                  if isYES "VM is up, do you realy want shutdown now"; then
                        CURRENTSAT=0
                        shutdownVMDOMAIN ${IMAGENAME} ${LIBVIRTHOST}
                  else
                        CURRENTSAT=1
                        exit 1
                  fi
            else
                  CURRENTSAT=1;
            fi
            CMD=$(echo ${CURRENTSAT})
            MSG="CURRENTSAT" && printlog "$CMD" "$MSG"

            # delete old release
            if [ ${CURRENTSAT} -eq 1 ]; then
                  #echo -n "        stop: " && sudo virsh destroy --domain ${VM_DOMAINNAME}
                  if isYES "do you realy want undefine source-image VM and displace it" 3600; then
                        CMD=$(sudo virsh destroy --domain  ${IMAGENAME})
                        MSG="virsh destroy"
                        printlog "$CMD" "$MSG"

                        CMD=$(sudo virsh undefine --domain ${IMAGENAME})
                        RET0=$?
                        MSG="virsh undefine"
                        printlog "$CMD" "$MSG"

                        VM_UNDFINED=0
                        VM_IP=
                  else
                        VM_UNDFINED=1
                        exit 1
                  fi
            fi
         fi
      fi

      echo "${dimblue}virt-install:";

      sudo virt-install \
      --connect=qemu:///system \
      --name=${IMAGENAME} \
      --ram=4096 \
      --vcpus=2 \
      --virt-type kvm \
      --arch=x86_64 \
      --disk path=${IMGAGEPATH}/${IMAGENAME}.qcow2,device=disk,bus=virtio,format=qcow2 \
      --os-type linux \
      --os-variant=ubuntu18.04 \
      --graphics none \
      --noautoconsole \
      --import \
      --debug

      wait
      echo ${reset};

       f=0
       FUNCTIONNAME=$(basename -- $0)
       QUIET=true
       while true; do
            getVM_IPfromDOMAIN ${IMAGENAME} ${LIBVIRTHOST};
            RET=$?
            if [ ! -z ${VM_IP} ]; then
                  thisCMD=$(printf "%-6s: getVM_IPfromDOMAIN: %s | VM_IP: %-15s" "$f" "$RET" "$VM_IP")
                  thisMSG="$FUNCTIONNAME  count"
                  printlog_function_out "${grey}$thisCMD" "$thisMSG"
                  break;
            else
                  sleep 2;
            fi
            (( f+=1 ))
            thisCMD=$(printf "%-6s: getVM_IPfromDOMAIN:%s  VM_IP :%-15s " "$f" "$RET" "$VM_IP")
            thisMSG="$FUNCTIONNAME  count"
            printlog_function_out "${grey}$thisCMD" "$thisMSG"
       done
       QUIET=

       isOnline ${VM_IP} 22 'isUP' ${IMAGENAME} ${LIBVIRTHOST}

       echo ${dimgreen}
       echo "                                       VM name : ${dimyellow}${IMAGENAME}${dimgreen}"
       echo "                           image file location : ${dimyellow}${IMGAGEPATH}/${IMAGENAME}.qcow 2${dimgreen}"
       echo ""
       echo "              the VM is now defined and online"
       echo "                            you can login over : ${dimyellow}ssh -A root@${VM_IP}${dimgreen}"
       echo "                                          user : ${dimyellow}root${dimgreen}"
       echo "                                      password : ${dimyellow}kankudai${dimgreen}"
       echo ""
       echo
       echo "           or reinstall the whole source again : ${dimyellow}./install-local-kanku-source${dimgreen}"
       echo ""
       echo "  NOTE: before colne this image with kanku, this VM should be shut off (cmd: sudo virsh shutdown ${IMAGENAME})"
       echo  ${reset}

       # terminal reset
       resize >/dev/null
else
       . lib/install-local-kanku-source.sh dhcp-default
fi #Eif fileExist ${IMGAGEPATH}/${IMAGENAME}".qcow2";

exit 0

#FIN


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

titleheader 'create new VM & install ubuntu' ${apricot};

# checkin the ini
if [ -L "configs/KankuFile.ini" ]; then
      INIFILE_fullpath=$(readlink -f configs/KankuFile.ini)
      INIFILE="${INIFILE_fullpath##*/}";
else
      INIFILE='KankuFile_dhcp-default.ini'
fi

# woring vars
IMAGENAME=$(cat configs/defaults/${INIFILE}|fgrep VM_IMAGENAME |sed 's/VM_IMAGENAME=//g'|cut -d "'" -f2)
DOMAIN=$(cat configs/defaults/${INIFILE}|fgrep VM_DOMAINNAME |sed 's/VM_DOMAINNAME=//g'|cut -d "'" -f2)
IMGAGEPATH=${HOME}/.cache/kanku
if [ ! -z ${VM_IMGAGESIZE} ]; then IMGAGESIZE=${VM_IMGAGESIZE}; else IMGAGESIZE=10; fi

# delete old source
if existVMDOMAIN ${IMAGENAME} ${LIBVIRTHOST}; then
      CMD=$(sudo virsh destroy --domain  ${IMAGENAME}) && MSG="${FUNCNAME[0]} virsh destroy" && printlog "$CMD" "$MSG"
      CMD=$(sudo virsh undefine --domain  ${IMAGENAME})
      RET0=$?
      MSG="${FUNCNAME[0]} virsh undefine" && printlog "$CMD" "$MSG"
      wait
else
      RET0=1
fi

####  virt-install  ####
ARCHITECTURE=x86_64
CHIPSET=${VM_CHIPSET}

echo -n "${orange}";
sudo virt-install \
--connect=qemu:///system \
--name=${IMAGENAME} \
--ram=4096 \
--vcpus=2 \
--virt-type kvm \
--arch=${ARCHITECTURE} \
--machine=${CHIPSET} \
--disk size=${IMGAGESIZE},format=qcow2,path=${IMGAGEPATH}/${IMAGENAME}_src.qcow2,bus=virtio,cache=none \
--initrd-inject=preseed.cfg \
--location 'http://archive.ubuntu.com/ubuntu/dists/bionic/main/installer-amd64' \
--os-type linux \
--os-variant=ubuntu18.04 \
--graphics none \
--console pty,target_type=serial \
--extra-args=" hostname="${IMAGENAME}" domain="${DOMAIN}" console=tty0 console=ttyS0,115200n8 serial" \
--debug \
--noreboot
RET1=$?
wait

####  qemu-img convert  ####
CMD=$(echo "${IMGAGEPATH}/${IMAGENAME}_src.qcow2 -> qcow2 ${IMGAGEPATH}/${IMAGENAME}.qcow2 ") && MSG="${FUNCNAME[0]} qemu-img convert" && printlog "$CMD" "$MSG"
echo -n "${orange}"
sudo qemu-img convert -p ${IMGAGEPATH}/${IMAGENAME}_src.qcow2 -O qcow2 ${IMGAGEPATH}/${IMAGENAME}.qcow2
RET2=$?
wait
echo -n ${reset};

# change ownership ans rights
CMD=$(sudo chmod -v 644 ${IMGAGEPATH}/${IMAGENAME}.qcow2;)
RET3=$?
MSG="${FUNCNAME[0]} chmod" && printlog "$CMD" "$MSG"

# shutdown domain, if up
LIBVIRTHOST=$(cat configs/defaults/${INIFILE}|fgrep LIBVIRTHOST |sed 's/LIBVIRTHOST=//g'|cut -d "'" -f2)
if isVMDOMAINrunning ${DOMAIN} ${LIBVIRTHOST}; then
   #shutdownVM_interactive ${VM_DOMAINNAME} ${LIBVIRTHOST}
   shutdownVMDOMAIN ${DOMAIN} ${LIBVIRTHOST}
fi

# remove domain
if existVMDOMAIN ${IMAGENAME} ${LIBVIRTHOST}; then
   CMD=$(sudo virsh undefine --domain ${IMAGENAME} --remove-all-storage)
   RET4=$?
   MSG="${FUNCNAME[0]} virsh undefine" && printlog "$CMD" "$MSG"
else
   RET4=1
fi

#remove src
if fileExist ${IMGAGEPATH}/${IMAGENAME}_src.qcow2; then
   CMD=$(rm -fv ${IMGAGEPATH}/${IMAGENAME}_src.qcow2)
   RET5=$?
   MSG="${FUNCNAME[0]} remove" && printlog "$CMD" "$MSG"
else
   RET5=1
fi

CMD=$(echo "RETs 0:"${RET0}" 1:"${RET1}" 2:"${RET2}" 3:"${RET3}" 4:"${RET4}" 5:"${RET5}) && MSG="${FUNCNAME[0]} return results" && printlog "$CMD" "$MSG"

#FIN

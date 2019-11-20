#!/bin/bash
# kankubunt - cause it's with kanku ... und bunt too
#
# prepare from the given .ini netplan an kanku-vars for there YAML-temlpates

# netplan #
. lib/render-netplan.sh

# kanku #
kanku_domain_name=${VM_KANKUPREFIX}"-"${VM_DOMAINNAME}  ##! namechanche is here

VM_IMAGEFILE=${VM_IMAGENAME}'.qcow2'  # local kanku-source-imagefile
kanku_vm_image_file=${VM_IMAGEFILE}

# now generated !
kanku_vm_template_file='kanku_u1804usVM.tt2'

# select network-type
CMD=$(echo "VM_NETWORK_TYPE="${VM_NETWORK_TYPE}) && MSG="network-type choosing" && printlog "$CMD" "$MSG"
case ${VM_NETWORK_TYPE} in
      static)
            kanku_ip=${VM_IP4_STATIC}
            if [ ! -z "$kanku_ip" ]; then
                  parseTemplate 'lib/kankufile-tmpls/KankuFile.ipaddress_template.yml' '/tmp/KankuFile.ipaddress_template.yml'
                  export IPADDRESS_STATIC="$(cat /tmp/KankuFile.ipaddress_template.yml)"
            else
                  export IPADDRESS_STATIC=''
            fi
      ;;
      dhcp|*)
            kanku_ip=
            export IPADDRESS_STATIC=''
      ;;
esac


CMD=$(echo "VM_NETWORK_INTERFACE="${VM_NETWORK_INTERFACE}) && MSG="network choosing" && printlog "$CMD" "$MSG"
case ${VM_NETWORK_INTERFACE} in
      bridge)
         kanku_host_interface=br0
         kanku_network_bridge=br0
         kanku_management_interface=eth0
         kanku_management_network=
         kanku_network_name=
         export NETWORKBRIDGE='network_bridge: '${kanku_network_bridge}
         export NETWORKNAME=''
      ;;
      default|*)
         kanku_host_interface=eth0
         kanku_network_bridge=virbr0
         kanku_management_interface=eth0
         CMD=$(echo "VM_NETWORK_TYPE="${VM_NETWORK_TYPE}) && MSG="network-type choosing" && printlog "$CMD" "$MSG"
         case ${VM_NETWORK_TYPE} in
            static)
                  kanku_management_network=
                  kanku_network_name=
            ;;
            dhcp|*)
                  kanku_management_network=default
                  kanku_network_name=default
                  export NETWORKBRIDGE=''
                  export NETWORKNAME='network_name: '${kanku_network_name}
            ;;
         esac
      ;;
esac

kanku_vcpu=${VM_VCPU}
kanku_memory=${VM_MEMORY}
kanku_use_cache=1
kanku_default_job=kanku-job

kanku_login_user=root
kanku_login_pass=kankudai
kanku_user=${USER}

kanku_images_dir=/var/lib/libvirt/images
kanku_cache_dir=${HOME}/.cache/kanku

kanku_use_9p=1
kanku_mnt_dir_9p=/tmp/kanku
kanku_noauto_9p=1


if [ ! -z ${VM_IMGAGESIZE} ]; then IMGAGESIZE=${VM_IMGAGESIZE}; else IMGAGESIZE=10; fi
kanku_disk_size=${IMGAGESIZE}"G"

export kanku_domain_name kanku_vm_image_file kanku_vm_template_file kanku_ip \
       kanku_host_interface kanku_network_bridge kanku_management_interface \
       kanku_management_network kanku_network_name kanku_vcpu kanku_memory \
       kanku_use_9p kanku_use_cache kanku_default_job kanku_login_user \
       kanku_login_pass kanku_user  kanku_images_dir kanku_cache_dir \
       kanku_mnt_dir_9p kanku_noauto_9p kanku_disk_size

# parse templates and generate final KankuFile


# tempate choosing
CMD=$(echo "VM_IMAGE_REV="${VM_IMAGE_REV}) && MSG="tempate choosing" && printlog "$CMD" "$MSG"
#if [ -z ${VM_IMAGE_REV} ] || [[ ${VM_IMAGE_REV} -eq 0 ]] || [[ $isRELEASE -eq 0 ]] || [[ $isREVISION -eq 1 ]] ; then
if [ -z ${VM_IMAGE_REV} ] || [[ ${VM_IMAGE_REV} -eq 0 ]] ; then
      # when no REV
      CMD=$(echo "${IMGAGESIZE}") && MSG="IMGAGESIZE" && printlog "$CMD" "$MSG"

      if [[ ${IMGAGESIZE} -gt 10 ]]; then
            # when imagesize is greater 10G #
            # count new name
            echo ${VM_IMAGENAME} | fgrep '_' > /dev/null
            if [[ $? -eq 0 ]] ; then
                  _SRC_IMAGENAME=$(echo ${VM_IMAGENAME} | cut  -d'_' -f1)
            else
                  _SRC_IMAGENAME=${VM_IMAGENAME}
            fi
            _NEW_IMAGENAME=${_SRC_IMAGENAME}"_"${VM_DOMAINNAME}

            # copy src-image
            CMD=$(cp -vP $HOME/.cache/kanku/u1804us.qcow2 $HOME/.cache/kanku/${_NEW_IMAGENAME}"_r0.qcow2" && wait)
            MSG="copy" && printlog "$CMD" "$MSG"

            # update ini
            VM_IMAGENAME=${_NEW_IMAGENAME}
            sed -i "s/VM_IMAGENAME=.*$/`echo VM_IMAGENAME=\'${_NEW_IMAGENAME}_r0\'`/g" configs/${INIFILE} ;

            # update local kanku-source-imagefile
            export kanku_vm_image_file=${_NEW_IMAGENAME}"_r0.qcow2"

            parseTemplate 'lib/kankufile-tmpls/KankuFile.first.template_resize.yml' 'KankuFile'
      else
            parseTemplate 'lib/kankufile-tmpls/KankuFile.first.template.yml' 'KankuFile'
      fi

else

      parseTemplate 'lib/kankufile-tmpls/KankuFile.second.template.yml' 'KankuFile'

fi

# remove routes, if present
if [ ! -z "$VM_ROUTES_TO_NETWORK" ]; then
      CMD=$(rm -v /tmp/00-netcfg-static_routes.yml) && MSG="remove" && printlog "$CMD" "$MSG"
fi

#FIN


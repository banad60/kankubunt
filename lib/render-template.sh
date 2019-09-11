#!/bin/bash
# kankubunt - cause it's with kanku ... und bunt too
#
# prepare from the given .ini netplan an kanku-vars for there YAML-temlpates

# netplan #
netplan_ethernets=${VM_ETHERNETS}                                    # the net-devive for netplan

netplan_addresses=${VM_IP4_STATIC}/${VM_IP4_NETMASK}                 #  (sequence of scalars) Example: addresses: [192.168.14.2/24, "2001:1::1/64"]

netplan_gateway4=${VM_IP4_GATEWAY}                                   # (scalar) Example for IPv4: gateway4: 172.16.0.1

netplan_gateway6=${VM_IP6_GATEWAY}                                   # (scalar) Example for IPv6: gateway6: "2001:4::1"

netplan_nameservers_addresses=${VM_NAMESERVERS_ADDRESSES}            # (mapping) Example: 8.8.8.8, "FEDC::1"
netplan_nameservers_search=${VM_NAMESERVERS_SEARCH}                  # (mapping) Examlpe: lab, home

netplan_routes_to_network=${VM_ROUTES_TO_NETWORK}
netplan_routes_to_via=${VM_ROUTES_TO_VIA}

if [ $VM_NETWORK_TYPE == 'dhcp' ]; then
      if [ ! -z $VM_IPV6_ON ]; then
         netplan_dhcp6='yes'
      else
         netplan_dhcp6='false'
      fi
else
   netplan_dhcp6='false'
fi

export netplan_ethernets netplan_addresses netplan_gateway4 netplan_gateway6 \
       netplan_nameservers_addresses netplan_nameservers_search \
       netplan_routes_to_network netplan_routes_to_via netplan_dhcp6

if [ ! -z "$VM_ROUTES_TO_NETWORK" ]; then
      parseTemplate 'lib/netplan-tmpls/00-netcfg_static_routes_tmpl.yml' '/tmp/00-netcfg-static_routes.yml'
      export ROUTES="$(cat /tmp/00-netcfg-static_routes.yml)"
else
      export ROUTES=''
fi
# EOF netplan #


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


export kanku_domain_name kanku_vm_image_file kanku_vm_template_file kanku_ip \
       kanku_host_interface kanku_network_bridge kanku_management_interface \
       kanku_management_network kanku_network_name kanku_vcpu kanku_memory \
       kanku_use_9p kanku_use_cache kanku_default_job kanku_login_user \
       kanku_login_pass kanku_user  kanku_images_dir kanku_cache_dir \
       kanku_mnt_dir_9p kanku_noauto_9p


# parse templates and generate final netplan.yaml & KankuFile
case ${VM_NETWORK_TYPE} in
    static) parseTemplate 'lib/netplan-tmpls/00-netcfg-static_tmpl.yml' 'fakeroot/etc/netplan/00-netcfg.yaml' ;;
    dhcp|*) parseTemplate 'lib/netplan-tmpls/00-netcfg-dhcp_tmpl.yml' 'fakeroot/etc/netplan/00-netcfg.yaml' ;;
esac

# tempate choosing
CMD=$(echo "VM_IMAGE_REV="${VM_IMAGE_REV}) && MSG="tempate choosing" && printlog "$CMD" "$MSG"
if [ -z ${VM_IMAGE_REV} ] || [ ${VM_IMAGE_REV} -eq 0 ] ; then
      parseTemplate 'lib/kankufile-tmpls/KankuFile.first.template.yml' 'KankuFile'
else
      parseTemplate 'lib/kankufile-tmpls/KankuFile.second.template.yml' 'KankuFile'
fi

# render routes, if present
if [ ! -z "$VM_ROUTES_TO_NETWORK" ]; then
      CMD=$(rm -v /tmp/00-netcfg-static_routes.yml) && MSG="remove" && printlog "$CMD" "$MSG"
fi

#FIN


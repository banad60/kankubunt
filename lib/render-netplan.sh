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

# parse templates and generate final netplan.yml
case ${VM_NETWORK_TYPE} in
    static) parseTemplate 'lib/netplan-tmpls/00-netcfg-static_tmpl.yml' 'fakeroot/etc/netplan/00-netcfg.yaml' ;;
    dhcp|*) parseTemplate 'lib/netplan-tmpls/00-netcfg-dhcp_tmpl.yml' 'fakeroot/etc/netplan/00-netcfg.yaml' ;;
esac

# EOF netplan #

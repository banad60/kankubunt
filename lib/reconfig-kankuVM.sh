#!/bin/bash
# kankubunt - cause it's with kanku ... und bunt too
#
# main script for reconfiguration of kanku
# as an example for working with different netzworks / chipsets / etc.

# get the lbrary, if non present
if [ -z ${TIMESTAMP} ]; then
   inLIBDIR=$(pwd|rev|cut -d'/' -f1|rev);
   if [ ${inLIBDIR} != 'lib' ]; then
      . lib/helper.sh
   else
      . helper.sh
   fi
fi

MSG=${TFS3}" usage: "$0" "${BRK1_R}"-f|--file <inifile>"${SPACER}"dhcp-default"${SPACER}"dhcp-bridge"${SPACER}"dhcp-bridge-mac"${SPACER}"static-default"${SPACER}"static-bridge"${BRK1_L}

if [ -z $1 ]; then

   echo ${MSG}${reset}
   export startRECONFIG=false
   exit 1

else

   # setup a start-flagg
   if [ ! -z ${startRECONFIG} ]; then unlink startRECONFIG; fi
   export startRECONFIG=true

   export TIMESTAMP

   export VM_KANKUPREFIX="kanku"
   titleheader 'reconf kanku-vm' ${blutorange};

   # get the inifile
   CONFIGDIR='configs'

   echo -n "${grey}"
   echo " # $# -> $ args: $*"
   echo -n "${reset}";

   case "$1" in
         dhcp-default)
              INIFILE='KankuFile_dhcp-default.ini'
         ;;
         dhcp-bridge)
              INIFILE='KankuFile_dhcp-bridge.ini'
         ;;
         dhcp-bridge-mac)
              INIFILE='KankuFile_dhcp-bridge-mac_DHCP-BRIDGE-MAC-vm.ini'
         ;;
         static-default)
              INIFILE='KankuFile_static-default_192.168.122.2.ini'
         ;;
         static-bridge)
              INIFILE='KankuFile_static-bridge_192.168.22.33.ini'
         ;;
         -f|--file)
               if fileExist $2 ; then
                  INIFILE=$(echo $2 | cut -d'/' -f2 )
               else
                  echo "ERROR: no Inifile found!! inifile must lay in 'configs/'"
                  ls -l ${CONFIGDIR}/
                  exit 1
               fi
         ;;
         *)
            echo "TYPO? "${MSG}
            exit 1
         ;;
   esac

   # checkin the ini
   if fileExist ${CONFIGDIR}/${INIFILE}; then
      if [ ${INIFILE} != 'KankuFile.ini' ]; then   # prevent overwriting, when file is KankuFile.ini
         ln -sf  ${INIFILE} ${CONFIGDIR}/KankuFile.ini
      fi
      # insert
      . ${CONFIGDIR}/${INIFILE};
   else
      echo "INI: "${CONFIGDIR}"/"${INIFILE};
      echo ${MSG}
      export startRECONFIG=false
      exit 1
      # no way without ini
   fi

   CMD=$(echo ${INIFILE};) && MSG="INIFILE"
   printlog "$CMD" "$MSG"

   CMD=$(echo ${LIBVIRTHOST}) && MSG="LIBVIRTHOST"
   printlog "$CMD" "$MSG"

   # check revision an put it to REV
   if [ ! -z $VM_IMAGE_REV ]; then REV=$VM_IMAGE_REV; else REV=0; fi
   export REV
   CMD=$(echo "${REV}") && MSG="REV" && printlog "$CMD" "$MSG"

   # shutdown released-image, if running (interactiv)
   shutdownVM_interactive ${VM_DOMAINNAME} ${LIBVIRTHOST}

   # check if mac is defined in .ini
   if [ ! -z ${VM_MAC} ]; then
            export VM_MAC
            CMD=$(echo ${VM_MAC})
            MSG="VM_MAC" && printlog "$CMD" "$MSG"
   fi

    #check hostkey-missmacht
    hkeyMEDICATE  "${VM_KANKUPREFIX}-${VM_DOMAINNAME}"  ${LIBVIRTHOST}

   # give thisIP a value
   if [ ! -z ${VM_IP4_STATIC} ]; then
      thisIP=${VM_IP4_STATIC}
   else
      thisIP=${hisIP} #<---!! Attentioni Toni - not sure!!!
   fi
   CMD=$(echo ${thisIP}) && MSG="thisIP" && printlog_result "$CMD" "$MSG"
   export thisIP;

   # store old domainname
   if fileExist 'KankuFile'; then
      OLD_KANKU_VM=$(cat KankuFile|fgrep domain_name|cut -d' ' -f2)
      # kanku destroy if old kanku-vm is running
      if [ ! -z ${OLD_KANKU_VM} ]; then
         if [ ! -z $LIBVIRTHOST ]; then
               OLD_KANKU_VM_STATUS=$(virsh -c qemu+ssh://root@${LIBVIRTHOST}/system list --all|fgrep ${OLD_KANKU_VM}|tr -s ' '|cut -d' ' -f4)
         else
               OLD_KANKU_VM_STATUS=$(virsh -c qemu:///system list --all|fgrep ${OLD_KANKU_VM}|tr -s ' '|cut -d' ' -f4)
         fi

         if isVMDOMAINrunning ${OLD_KANKU_VM} ${LIBVIRTHOST}; then
            CMD=$(echo ${OLD_KANKU_VM} ${OLD_KANKU_VM_STATUS}) && MSG="STATUS OLD_KANKU_VM" && printlog_result "$CMD" "$MSG"

            titleheader 'kanku destroy' ${red};
            kanku destroy;

            titleheader 'reconf kanku-vm' ${grey};
         fi
      fi
      rm KankuFile
   fi


   # copy mashine-templateS
   TEMPLATE_DIR=/etc/kanku/templates
   setup_file 'fakeroot/etc/kanku/templates/default-vm.tt2' ${TEMPLATE_DIR}/default-vm.tt2

   CMD=$(echo ${VM_CHIPSET}) && MSG="VM_CHIPSET" && printlog "$CMD" "$MSG"
   CMD=$(echo ${VM_NETWORK_INTERFACE}) && MSG="VM_NETWORK_INTERFACE" && printlog "$CMD" "$MSG"

   # define template var
   CMD=$(echo ${VM_MAC}) && MSG="VM_MAC" && printlog "$CMD" "$MSG"
   if [ ! -z "${VM_MAC}" ]; then
         export VM_INTERFACE_MAC="<mac address='"${VM_MAC}"'/>"
   else
         export VM_INTERFACE_MAC=''
   fi

   # get network-status off new VM
   if [ ${VM_NETWORK_INTERFACE} == "default" ]; then
         VM_NTYPE='network';
         VM_NSOURCE="<source network='[% domain.network_name %]'/>"
   else
         VM_NTYPE='bridge';
         VM_NSOURCE="<source bridge='[% domain.network_bridge %]'/>"
   fi

   # render the kanku_u1804usVM_if.tt2
   parseTemplate 'lib/kankufile-tmpls/kanku_u1804usVM_if.tt2.tmpl' '/tmp/kanku_u1804usVM_if.tt2'
   export INTERFACE="$(cat /tmp/kanku_u1804usVM_if.tt2)"

   case ${VM_CHIPSET} in
      q35)
        export VM_PCI_MODEL='pcie-root'
     ;;
      pc|*)
         export VM_PCI_MODEL='pci-root'
   esac

   #echo " *  render: kanku_u1804usVM.tt2.tmpl";
   parseTemplate 'lib/kankufile-tmpls/kanku_u1804usVM.tt2.tmpl' 'fakeroot'${TEMPLATE_DIR}'/kanku_u1804usVM.tt2'
   setup_file 'fakeroot'${TEMPLATE_DIR}'/kanku_u1804usVM.tt2' ${TEMPLATE_DIR}/kanku_u1804usVM.tt2

   # make netplan.io and Kankufile
   . lib/render-template.sh

   if [ -z ${callRECONFIG} ] ; then
         titleheader 'kanku up' ${green};
         kanku up;

         # terminal reset
         resize >/dev/null

         # if no revision, ingrease to r1
         if [[ $REV -eq 0 ]] || [ -z $VM_IMAGE_REV ]; then
               . lib/fork-local-kanku-source.sh
         fi
   fi

   export startRECONFIG=false
fi




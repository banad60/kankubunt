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
   export noBAK=

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
      # insert inifile
#      . ${CONFIGDIR}/${INIFILE};
       INIFILE_fullpath=$(readlink -f ${CONFIGDIR}/KankuFile.ini)
       . ${INIFILE_fullpath}
   else
      echo "INI: "${CONFIGDIR}"/"${INIFILE};
      echo ${MSG}
      export startRECONFIG=false
      exit 1
      # no way without ini
   fi

   THIS_KANKU_VM="${VM_KANKUPREFIX}-${VM_DOMAINNAME}"

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
#    hkeyMEDICATE  "${VM_KANKUPREFIX}-${VM_DOMAINNAME}"  ${LIBVIRTHOST}
    hkeyMEDICATE "${THIS_KANKU_VM}" ${LIBVIRTHOST}

   # give thisIP a value
   if [ ! -z ${VM_IP4_STATIC} ]; then
      thisIP=${VM_IP4_STATIC}
   else
      thisIP=${hisIP} #<---!! Attentioni Toni - not sure!!!
   fi
   CMD=$(echo ${thisIP}) && MSG="thisIP" && printlog_result "$CMD" "$MSG"
   export thisIP;

   #check for release function
   ini_IMAGENAME=
   ini_REVISIONNAME=
   ini_VM_IMAGE_REV=
   ini_VM_RELEASE=
   isRELEASE=
   isREVISION=
   chkRelease () {
         CMD=$(echo "do check for release") && MSG="check" && printlog "$CMD" "$MSG"

         ini_IMAGENAME=$(cat ${CONFIGDIR}/${INIFILE} | fgrep VM_IMAGENAME | sed 's/VM_IMAGENAME=//g' | cut -d "'" -f2)
         export ini_IMAGENAME
         CMD=$(echo ${ini_IMAGENAME}) && MSG="ini_IMAGENAME" && printlog "$CMD" "$MSG"

         ini_REVISIONNAME=$(echo $ini_IMAGENAME | rev | cut -d'_' -f2- | rev )
         export ini_REVISIONNAME
         CMD=$(echo ${ini_REVISIONNAME}) && MSG="ini_REVISIONNAME" && printlog "$CMD" "$MSG"

         ini_VM_IMAGE_REV=$(cat ${CONFIGDIR}/${INIFILE} | fgrep VM_IMAGE_REV | sed 's/VM_IMAGE_REV=//g' | cut -d "'" -f2)
         export VM_IMAGE_REV
         CMD=$(echo ${ini_VM_IMAGE_REV}) && MSG="ini_VM_IMAGE_REV" && printlog "$CMD" "$MSG"

         ini_VM_RELEASE=$(cat ${CONFIGDIR}/${INIFILE} | fgrep VM_RELEASE | sed 's/VM_RELEASE=//g' | cut -d "'" -f2)
         export ini_VM_RELEASE
         if [ -z $ini_VM_RELEASE ]; then ini_VM_RELEASE=0; fi
         CMD=$(echo ${ini_VM_RELEASE}) && MSG="ini_VM_RELEASE" && printlog "$CMD" "$MSG"

         QUIET=true

         if existVMDOMAIN ${VM_DOMAINNAME} ${LIBVIRTHOST}; then isRELEASE=0; else isRELEASE=1; fi
         export isRELEASE
         CMD=$(echo ${isRELEASE}) && MSG="isRELEASE" && printlog "$CMD" "$MSG"

         if existVMDOMAIN "kanku-"${VM_DOMAINNAME} ${LIBVIRTHOST}; then isREVISION=0; else isREVISION=1; fi
         export isREVISION
         CMD=$(echo ${isREVISION}) && MSG="isREVISION" && printlog "$CMD" "$MSG"

         QUIET=

         if [[ ${isRELEASE} -eq 0 ]] && [[ ${isREVISION} -eq 1 ]]; then
               local thisMSG="there is a release but no revison"
               sed -i "s/VM_IMAGE_REV=.*$/`echo VM_IMAGE_REV=0`/g" ${INIFILE_fullpath} ;
               sed -i "s/VM_IMAGENAME=.*$/`echo VM_IMAGENAME=\'u1804us\'`/g" ${INIFILE_fullpath} ;
         elif [[ ${isRELEASE} -eq 0 ]] && [[ ${isREVISION} -eq 0 ]]; then
               local thisMSG="there is a release and a revison"
               echo "ini_VM_RELEASE  : $ini_VM_RELEASE"
               echo "ini_VM_IMAGE_REV: $ini_VM_IMAGE_REV"
         elif [[ ${isRELEASE} -eq 1 ]] && [[ ${isREVISION} -eq 0 ]]; then
               local thisMSG="there is no release but a revison"
               echo "ini_VM_IMAGE_REV: $ini_VM_IMAGE_REV"
         else
               local thisMSG="there is no release and no revison"
         fi

         if [ ! -z $REV ]; then
               CMD=$(echo "${REV}") && MSG="REV" && printlog "$CMD" "$MSG"
         fi
         CMD=$(echo $thisMSG) && MSG="check" && printlog "$CMD" "$MSG"
   } #EoF


   # when a KankuFile ist present
   if fileExist 'KankuFile'; then
         # store old domainname
         OLD_KANKU_VM=$(cat KankuFile|fgrep domain_name|cut -d' ' -f2)
         CMD=$(echo ${OLD_KANKU_VM}) && MSG="OLD_KANKU_VM" && printlog_result "$CMD" "$MSG"

         CMD=$(echo ${THIS_KANKU_VM}) && MSG="THIS_KANKU_VM" && printlog_result "$CMD" "$MSG"

         # different handling if changing the VM
         if [ "${THIS_KANKU_VM}" ==  "${OLD_KANKU_VM}" ]; then
               # when not changing the VM
               ### kanku destroy if old kanku-vm is running
               if [ ! -z ${OLD_KANKU_VM} ]; then
                  if [ ! -z $LIBVIRTHOST ]; then
                        OLD_KANKU_VM_STATUS=$(virsh -c qemu+ssh://root@${LIBVIRTHOST}/system list --all|fgrep ${OLD_KANKU_VM}|tr -s ' '|cut -d' ' -f4-)
                  else
                        OLD_KANKU_VM_STATUS=$(virsh -c qemu:///system list --all|fgrep ${OLD_KANKU_VM}|tr -s ' '|cut -d' ' -f4-)
                  fi
                  # INFO: not needed for the moment (may be later again) - if the kanku-VM have different IPs and there is no released VM
                  if isVMDOMAINrunning ${OLD_KANKU_VM} ${LIBVIRTHOST}; then
                     CMD=$(echo ${OLD_KANKU_VM_STATUS}) && MSG="STATUS OLD_KANKU_VM" && printlog_result "$CMD" "$MSG"
         #            titleheader 'kanku destroy' ${red};
         #            kanku destroy;
         #            titleheader 'reconf kanku-vm' ${grey};
                  fi
               fi

         #      rm KankuFile
               CMD=$(echo "active KankuFile!") && MSG="exit" && printlog_result_err "$CMD" "$MSG"

         #      echo "${reset}"
               echo -n ${dimred}
               echo "! at this time you can not reconfigure, because there is an active KankuFile with ${orange}${OLD_KANKU_VM_STATUS}${dimred} state!"
               echo -n ${dimgreen}
               echo "                                 your options for now are"
               echo "                                         make a revision : ${dimyellow}./revision-kanku-vm${dimgreen}"
               echo "                                          make a release : ${dimyellow}./release-kanku-vm${dimgreen}"
               echo ${reset}

               exit 1
         else
               # when changing the VM, stor KankuFile
               OLD_VM=$(echo ${OLD_KANKU_VM} | sed 's/kanku-//g' )
               DOM_DIRNAME="u1804us_"${OLD_VM}
               CMD=$(mkdir -pv KankuFiles/${DOM_DIRNAME}) && MSG="mkdir" && printlog "$CMD" "$MSG"

               OLD_REV=$(cat KankuFile | fgrep vm_image_file | sed 's/vm_image_file: //g' | cut -d '.' -f1 | rev | cut -d '_' -f1 | rev )
               CMD=$(echo $OLD_REV) && MSG="OLD_REV" && printlog "$CMD" "$MSG"

               if fileExist KankuFiles/${DOM_DIRNAME}/*"_"${OLD_REV}".yml"; then
                  rm KankuFiles/${DOM_DIRNAME}/*"_"${OLD_REV}".yml"
               fi

               OLD_IMAGENAME="_"${TIMESTAMP}"_KankuFile_"${DOM_DIRNAME}"_"${OLD_REV}".yml"
               CMD=$(mv -fv KankuFile KankuFiles/${DOM_DIRNAME}/${OLD_IMAGENAME}) && MSG="move" && printlog "$CMD" "$MSG"

               chkRelease
         fi #Eif [ "${THIS_KANKU_VM}" ==  "${OLD_KANKU_VM}" ];
   else
         #check for release
         chkRelease
   fi #Eif fileExist 'KankuFile'


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

   parseTemplate 'lib/kankufile-tmpls/kanku_u1804usVM.tt2.tmpl' 'fakeroot'${TEMPLATE_DIR}'/kanku_u1804usVM.tt2'
   setup_file 'fakeroot'${TEMPLATE_DIR}'/kanku_u1804usVM.tt2' ${TEMPLATE_DIR}/kanku_u1804usVM.tt2


   # compute 
   if [[ $isRELEASE -eq 0 ]] ; then
         # if release exists
         # test for revision
         RET=
         if [[ ${isREVISION} -eq 0 ]]; then
               _DOM_DIRNAME_r=${ini_IMAGENAME}
               echo ${_DOM_DIRNAME_r} | fgrep "_r${ini_VM_IMAGE_REV}" > /dev/null
               RET=$? #fargwürdig
               _DOM_DIRNAME=$(echo ${ini_IMAGENAME} | rev | cut -d'_' -f2- | rev)
         else
               _DOM_DIRNAME_r='null'
               _DOM_DIRNAME="u1804us_"${VM_DOMAINNAME}
         fi
         echo "_DOM_DIRNAME_r    : ${_DOM_DIRNAME_r}"
         echo "_DOM_DIRNAME      : $_DOM_DIRNAME"

         if ! fileExist $HOME/.cache/kanku/$_DOM_DIRNAME_r".qcow2"; then
               #when there is no revision-image
               echo "RET    : ${RET}"
               if [[ $RET -eq 0 ]]; then
                     if dirExist ./KankuFiles/$_DOM_DIRNAME; then
                           # scan dir and store KankuFiles to var
                           ii=0
                           for KANKUFILE in KankuFiles/$_DOM_DIRNAME/*.yml; do
                                 logStamp
                                 printf "${grey}${LOGSTAMP} ${dimblue}%-3s ${dimcyan}%-30s : ${dimwhite}%s${reset}\n" "$ii" "$_DOM_DIRNAME"  "$KANKUFILE"
                                 KANKUFILES+=${KANKUFILE}" "
                                 logStamp
                                 (( ii+=1 ))
                           done
                           KANKUFILES_NUM=$ii
                           printf "${grey}${LOGSTAMP} ${dimblue}%-3s ${dimcyan}%-30s : ${dimwhite}%s${reset}\n" "#" "KANKUFILES_NUM"  "$KANKUFILES_NUM"

                           # format and stor var to file
                           tmp=$(mktemp /tmp/tmp.XXX);
                           echo ${KANKUFILES} | sed 's/^[ \t]*//;s/[ \t]*$//' | tr -s ' ' | tr '[:space:]' '\n' | sort --version-sort  > $tmp;
                           # declare the array from file
                           declare -a thisKANKUFILES=(`cat $tmp`)
                           export thisKANKUFILES
                           rm $tmp

                           #workout the KankuFiles
                           KEYS=(${!thisKANKUFILES[@]});
                           for (( ii=0; $ii < ${#thisKANKUFILES[@]}; ii+=1 )); do
                                 LASTKEY=$KEY
                                 KEY=${KEYS[$ii]};
                                 NUM=$KEY && ((NUM+=1)); # linecount

                                 thisCMD=$(echo "${thisKANKUFILES[$KEY]}")
                                 thisMSG='$thisKANKUFILES['$KEY"]"
                                 printlog_list "$thisCMD" "$thisMSG" "$NUM" "$KEY"

                                 #$(
#											echo "${thisKANKUFILES[$KEY]}" | grep '_r'
#											echo "${thisKANKUFILES[$KEY]}" | grep '_1.00-'
                                 #)

                                 if [[ $ii -gt 0 ]]; then
#													diff -s --color "$PWD/${thisKANKUFILES[$LASTKEY]}" "$PWD/${thisKANKUFILES[$KEY]}" | sudo tee -a ${thisKANKUFILES[$KEY]}.patch
                                       export noBAK=true
                                       . lib/fork-local-kanku-source.sh
                                       export noBAK=
                                 else
                                       echo "configure netplan"
                                       . lib/render-netplan.sh
                                 fi

                                 if fileExist 'KankuFile'; then
                                       rm KankuFile
                                 fi

                                 CMD=$(cp -v $PWD/${thisKANKUFILES[$KEY]} KankuFile)
                                 #CMD=$(cp -v $PWD/${thisKANKUFILES[$KEY]} KankuFile)
                                 MSG="copy" && printlog "$CMD" "$MSG"

                                 echo -n "${grey}"
                                 cat KankuFile
                                 echo -n "${reset}"

                                 titleheader 'kanku up' ${grey};
                                 kanku up
                           done

                           CMD=$(echo "finished ${grey}VM_IMAGE_REV=$ini_VM_IMAGE_REV VM_RELEASE=$ini_VM_RELEASE")
                           MSG="reconstruction" && printlog_result "$CMD" "$MSG"

                     fi #Eif dirExist ./KankuFiles/$_DOM_DIRNAME;
               else
                     # make netplan.io and Kankufile
                     . lib/render-template.sh
               fi #Eif [[ $RET -eq 0 ]];
         else
               #when there a revision-image
               # choose released KankuFile if no revisoned KankuFile
               KANKUFILENAME="_KankuFile_"$_DOM_DIRNAME"_r"${ini_VM_IMAGE_REV}".yml"
               if ! fileExist KankuFiles/$_DOM_DIRNAME/*$KANKUFILENAME; then
                     KANKUFILENAME="_KankuFile_"$_DOM_DIRNAME"_1.00-"${ini_VM_IMAGE_REV}".yml"
               fi
               CMD=$(echo $KANKUFILENAME) && MSG="KANKUFILENAME" && printlog "$CMD" "$MSG"

               CMD=$(cp -v KankuFiles/$_DOM_DIRNAME/*$KANKUFILENAME KankuFile)
               MSG="copy" && printlog "$CMD" "$MSG"
         fi #Eif ! fileExist $HOME/.cache/kanku/$_DOM_DIRNAME_r".qcow2"
   else
         # if no release
         #KANKUFILENAME="_KankuFile_"$DOM_DIRNAME"_r"${VM_IMAGE_REV}".yml"
         DOM_DIRNAME=$(echo ${VM_IMAGENAME} | rev | cut -d '_' -f2- | rev )
         KANKUFILENAME="_KankuFile_"$DOM_DIRNAME"_r"${VM_IMAGE_REV}".yml"
         #$(echo ${VM_IMAGENAME} | rev | cut -d '_' -f2- | rev )
         CMD=$(echo $KANKUFILENAME) && MSG="KANKUFILENAME" && printlog "$CMD" "$MSG"

         if fileExist KankuFiles/$DOM_DIRNAME/*$KANKUFILENAME; then
#            cp -v KankuFiles/$_DOM_DIRNAME/*$_DOM_DIRNAME"_"${REV}".yml" KankuFile
            CMD=$(cp -v KankuFiles/$DOM_DIRNAME/*$KANKUFILENAME KankuFile)
            MSG="copy" && printlog "$CMD" "$MSG"
         else
            # make netplan.io and Kankufile
            . lib/render-template.sh
         fi
   fi #Eif [[ $isRELEASE -eq 0 ]]

   # start VM if not running
   if [ -z ${callRECONFIG} ] ; then
         QUIET=true
         if [[ $REV -gt 0 ]] ; then

            if ! isVMDOMAINrunning ${THIS_KANKU_VM} ${LIBVIRTHOST}; then
                  startupVMDOMAIN ${THIS_KANKU_VM} ${LIBVIRTHOST};
            else
                  getVM_IPfromDOMAIN ${THIS_KANKU_VM} ${LIBVIRTHOST}
                  echo -n ${dimgreen}
                  echo "                                               ssh login : ${dimyellow}ssh -A root@${VM_IP}${dimgreen}"
                  echo -n ${reset}
            fi
         else
            if ! isVMDOMAINrunning ${THIS_KANKU_VM} ${LIBVIRTHOST}; then
               titleheader 'kanku up' ${green};
               kanku up;
            fi
         fi
         QUIET=
         # terminal reset
         resize >/dev/null

         # if no revision, ingrease to r1
         if [[ $REV -eq 0 ]] || [ -z $VM_IMAGE_REV ]; then
               . lib/fork-local-kanku-source.sh
         fi
   fi

   export startRECONFIG=false
fi

#FIN


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
      titleheader 'reset-ini' ${brown};
      export TIMESTAMP
      export VM_KANKUPREFIX="kanku"

      iniPATH='configs'
      iniPATH_defaults="${iniPATH}/defaults"
      if [ -L "configs/KankuFile.ini" ]; then
            #get the old ini and count  its defaults
            INIFILE_fullpath=$(readlink -f configs/KankuFile.ini)
            INIFILE="${INIFILE_fullpath##*/}";
      else
            INIFILE="KankuFile_dhcp-default.ini";
      fi
      . configs/${INIFILE}
      INIFILEabs=${iniPATH}/${INIFILE}
      INIFILEabs_defaults=${iniPATH_defaults}/${INIFILE}

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
      CMD=$(echo ${REV}) && MSG="$0 - REV" && printlog "$CMD" "$MSG"

      if [[ ${REV} -gt 0 ]]; then
            _REVISION_NAME=$(cat KankuFile|fgrep vm_image_file|sed 's/^[ \t]*//'|cut -d' ' -f2 | cut -d'.' -f1 | cut -d'_' -f1-2)
            CMD=$(echo ${_REVISION_NAME}) && MSG="_REVISION_NAME" && printlog "$CMD" "$MSG"

            # get cache_dir
            IMGAGEPATH=$(cat KankuFile|fgrep cache_dir|sed 's/^[ \t]*//'|cut -d' ' -f2)
            CMD=$(echo "${IMGAGEPATH}") && MSG="IMGAGEPATH" && printlog "$CMD" "$MSG"

            # remove all kanku-revisions-images
            if fileExist ${IMGAGEPATH}/${_REVISION_NAME}"_r"${REV}".qcow2"; then
                  #echo -n " *  remove: "
                  CMD=$(rm -vf ${IMGAGEPATH}/${_REVISION_NAME}_* | sed "s/'/\"/g" | cut -d ' ' -f1 | sed 's/"//g' | sed ':a; N; s/\n/, /; ta')
                  MSG="remove" && printlog "$CMD" "$MSG"
            else
                  CMD=$(echo "no ${_REVISION_NAME}_* images - nothing to do!")
                  MSG="remove" && printlog "$CMD" "$MSG"
            fi
      fi

      # ############################### kanku destroy
      DOMAIN=$(cat KankuFile|fgrep domain_name|sed 's/^[ \t]*//'|cut -d' ' -f2)
      CMD=$(echo ${DOMAIN}) && MSG="DOMAIN" && printlog "$CMD" "$MSG"
      if existVMDOMAIN ${DOMAIN} ${LIBVIRTHOST}; then
            titleheader 'kanku destroy' ${red};
            kanku destroy;
            titleheader 'reset-ini' ${grey};
      fi

      #backup ini
      setup_file ${INIFILEabs_defaults} ${INIFILEabs}

      # resets controllvar
      VM_IMAGE_REV=


      # insert new ini
      . ${INIFILEabs}

      #render new netplan, .tt2 and KankuFile
      . lib/render-template.sh

fi; #Eif [ ! -f "KankuFile" ]

# ############################### kanku up
titleheader 'kanku up' ${green};
kanku up;

# terminal reset
resize >/dev/null



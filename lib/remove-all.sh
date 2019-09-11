#!/bin/bash
# kankubunt - cause it's with kanku ... und bunt too

if [ -z ${TIMESTAMP} ]; then . lib/helper.sh; fi

titleheader '! kankubunt remove all images and configs !' ${pink};

if fileExist KankuFile; then
   titleheader '! kanku destroy !' ${red};
   kanku destroy

   titleheader '! kankubunt remove all images and configs !' ${grey};

   unset_file KankuFile
else
   printf "${dimmagenta} *  status: ${dimcyan}%-75s ${dimwhite}%2s ${grey}%s\n" "ok -no files" "->" "KankuFile"
fi

unsetFILES () {
		for thisFILEs in $1; do
		      unset_file $thisFILEs
		done
}

echo -n ${dimmagenta}
unsetFILES 'configs/KankuFile*.ini'
unsetFILES 'configs/*.patch'
unsetFILES 'configs/*.bak'
if [ -L configs/*ini.last.bak ]; then sudo unlink configs/*ini.last.bak; fi
if [ -L configs/*ini.last.patch ]; then sudo unlink configs/*ini.last.patch; fi


#echo -n ${dimyellow}
echo -n ${dimyellow}
COPYCMD=$(cp -vp configs/defaults/KankuFile.ini configs)
printf "${dimyellow} *    copy: ${ocker}%-75s ${dimwhite}%2s ${dimyellow}%s\n" ${COPYCMD}

echo -n ${ocker}
COPYCMD=$(cp -vp configs/defaults/*.ini configs )
printf "${dimyellow} *    copy: ${ocker}%-75s ${dimwhite}%2s ${dimyellow}%s\n" ${COPYCMD}


echo -n ${dimmagenta}
unset_file fakeroot/etc/kanku/templates/kanku_u1804usVM.tt2
unset_file fakeroot/etc/netplan/00-netcfg.yaml
echo -n ${reset}

DIR='$HOME/.cache/kanku/u1804us*.qcow2'
if [ "$(ls -A $HOME/.cache/kanku)" ]; then
   #echo -n ${dimyellow}
   echo -n ${ocker}
   unset_file $HOME/.cache/kanku/u1804us*.qcow2
else
   printf "${dimmagenta} *  status: ${dimcyan}%-75s ${dimwhite}%2s ${grey}%s\n" "ok -no files" "->" "$HOME/.cache/kanku/u1804us*.qcow2"
fi


DIR='/var/lib/libvirt/images'
if [ "$(sudo ls -A $DIR)" ]; then
   echo -n ${dimyellow}
   #echo -n ${ocker}
   FILES='/var/lib/libvirt/images/kanku-*.qcow2'
   if fileExist $FILES; then
      sudo rm -vf $FILES
   else
      #echo "${dimmagenta} *  status: no files : /var/lib/libvirt/images/kanku-*.qcow2"
      printf "${dimmagenta} *  status: ${dimcyan}%-75s ${dimwhite}%2s ${grey}%s\n" "ok -no files" "->" "$FILES"
   fi
else
   #echo "${dimmagenta} *  status:  no files : /var/lib/libvirt/images"
   printf "${dimmagenta} *  status: ${dimcyan}%-75s ${dimwhite}%2s ${grey}%s\n" "ok -no files" "->" "$DIR"
fi


exit 0


#FIN

#!/bin/bash

source /home/dante/dantescript/common-defs.sh

printf "\n*** *** *** THIS IS /home/dante/dantescript/copy-out.sh ***** "


trap 'abort' ERR                       # call abort on error

exec 1>&1 2>&2

#
# Delete old stuff. Must do this for ${TARGET} and ***NOT*** for /mnt, since there are
# some files we still need !
#
printf "\n*** copy-out.sh: removing old stuff...\n "
  rm -rf /mnt/${TARGET} ; rm -f /mnt/.DS_Store ;  exec 1>&1 2>&2
printf "DONE cleaning up old stuff\n"

## TODO: some stuff does not get deleted properly. why? check this !! problem, if there is an old file still there which gets used

printf "\n*** copy-out.sh: verifying removal of old stuff \n "
  ls -la /mnt ; exec 1>&1 2>&2
printf "DONE cleaning up old stuff\n"

printf "\n*** copy-out.sh: cleaning up old stuff..LS \n "
  ls -ld /mnt ; exec 1>&1 2>&2
printf "DONE cleaning up old stuff\n"

## copy out what we have just produced from 
printf "\n\n*** copy-out.sh: copying out...\n"
  cp -a ${MOUNT}/${TARGET} /mnt
  exec 1>&1 2>&2
printf "DONE cleaning up old stuff\n"

printf "\n*** copy-out.sh: Copying in index.html and favicon.ico and error404.php to /mnt ..."
  cp /home/dante/html/index.html    /mnt
  cp /home/dante/html/favicon.ico   /mnt
  cp /home/dante/html/error.php     /mnt

  exec 1>&1 2>&2
printf "DONE\n"



printf "\n***  copy-out.sh: doing an LS after the copying operation \n "
  ls -lag /mnt ; exec 1>&1 2>&2
printf "DONE cleaning up old stuff\n"

printf "*** /home/dante/dantescript/copy-out.sh has completed. GOOD BYE\n"
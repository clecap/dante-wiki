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

printf "\n*** copy-out.sh: Listing the source directory ${MOUNT} \n "
  ls -la ${MOUNT} ; exec 1>&1 2>&2
printf "DONE listing the source directory\n"

## copy out what we have just produced from 
printf "\n\n*** copy-out.sh: copying out ${MOUNT} to /mnt \n"
#### was ${MOUNT}/${TARGET}



  printf "\n COPY TIMING with cp \n"
  time ( cp -a ${MOUNT}/${TARGET} /mnt )
  printf "\n DONE OPCY TIMING with cp \n"

##### TODO: studying possibilities of speeding this up
#  printf "\n COPY TIMING with rsync \n"
# rsync -a ${MOUNT}/${TARGET} /mnt/  
#  printf "\n DONE OPCY TIMING with crsync \n"


####
#  printf "\n COPY TIMING with parallel \n"
##  find ${MOUNT}/${TARGET} | parallel -j 8 cp {} /mnt/
#  printf "\n DONE COPY TIMING with parallel \n"






  trap - ERR
  cp -p ${MOUNT}/* /mnt
  trap 'abot' ERR
  exec 1>&1 2>&2
printf "DONE cleaning up old stuff\n"


printf "\n***  copy-out.sh: listing /mnt (after the copy operation) \n "
  ls -lag /mnt ; exec 1>&1 2>&2
printf "DONE cleaning up old stuff\n"

trap - ERR

printf "*** /home/dante/dantescript/copy-out.sh has completed. GOOD BYE\n"
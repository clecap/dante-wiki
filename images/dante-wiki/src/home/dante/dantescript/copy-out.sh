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

stdbuf -o0 -e0 printf "\n*** copy-out.sh: verifying removal of old stuff \n "
  stdbuf -o0 -e0 ls -la /mnt ; exec 1>&1 2>&2
stdbuf -o0 -e0 printf "DONE cleaning up old stuff\n"

stdbuf -o0 -e0 printf "\n*** copy-out.sh: cleaning up old stuff..LS \n "
  stdbuf -o0 -e0 ls -ld /mnt ; exec 1>&1 2>&2
stdbuf -o0 -e0 printf "DONE cleaning up old stuff\n"

stdbuf -o0 -e0 printf "\n*** copy-out.sh: Listing the source directory ${MOUNT} \n "
  stdbuf -o0 -e0 ls -la ${MOUNT} ; exec 1>&1 2>&2
stdbuf -o0 -e0 printf "DONE listing the source directory\n"


### THIS is the fast version of copying
mkdir -p /mnt/${TARGET}
stdbuf -o0 -e0 printf "\n COPY ${MOUNT}/${TARGET} with GNU parallel \n"
#stdbuf -o0 -e0  time ( find /var/www/html -mindepth 2 -maxdepth 2 -type d | parallel -j 16 -X cp -ap {} /mnt/${TARGET}/{/} )
# The above stdbuf command does not work for some reason :-(
time ( find ${MOUNT}/${TARGET} -mindepth 1 -maxdepth 1 -type d | parallel -j 16 -X cp -ap {} /mnt/${TARGET}/ )
stdbuf -o0 -e0 printf "\n DONE COPY TIMING with GNU parallel \n"

#### THIS is the slow version of cpying
#stdbuf -o0 -e0 printf "\n COPY ${MOUNT}/${TARGET} with cp \n"
#time ( cp -a ${MOUNT}/${TARGET} /mnt )
#stdbuf -o0 -e0 printf "\n DONE COPY ${MOUNT}/${TARGET} with cp \n"
#  this took 1minute 22 sec ;  1 minute 7 sec

## copy out a small number of remaining things
stdbuf -o0 -e0 printf "\n\n*** copy-out.sh: copying out ${MOUNT} to /mnt \n"

  find ${MOUNT}/${TARGET} -type f -exec cp {} /mnt/${TARGET} \;

#   cp -p ${MOUNT}/${TARGET}/* /mnt/${TARGET}
  cp -a ${MOUNT}/experimental /mnt
  trap - ERR
  cp -p ${MOUNT}/* /mnt
  exec 1>&1 2>&2
printf "DONE cleaning up old stuff\n"


printf "\n***  copy-out.sh: listing /mnt (after the copy operation) \n "
  ls -lag /mnt ; exec 1>&1 2>&2
printf "DONE cleaning up old stuff\n"

trap - ERR

printf "*** /home/dante/dantescript/copy-out.sh has completed. GOOD BYE\n"
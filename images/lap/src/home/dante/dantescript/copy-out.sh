#!/bin/bash

printf "\n*** *** *** THIS IS /home/dante/dantescript/copy-out.sh ***** "

### set terminate on error 
#abort()
#{
#  printf "%b" "\e[1;31m *** *** *** ABORTED *** *** *** \e[0m"
#  exit 1
#}
#set -e                                  # abort execution on any error
#trap 'abort' EXIT                       # call abort on EXIT

MOUNT=/var/www/html/
TARGET=wiki-dir

exec 1>&1 2>&2

printf "\n***  /home/dante/dantescript/copy-out.sh: cleaning up old stuff...\n "
  chown -R www-data:www-data /mnt/${TARGET}
  exec 1>&1 2>&2
printf "DONE cleaning up old stuff\n"


#
# Delete old stuff. Must do this for ${TARGET} and ***NOT*** for /mnt, since there are
# some files we still need !
#
printf "\n***  /home/dante/dantescript/copy-out.sh: cleaning up old stuff...\n "
  rm -rf /mnt/${TARGET}
  exec 1>&1 2>&2
printf "DONE cleaning up old stuff\n"


## TODO: some stuff does not get deleted properly. why? check this !! problem, if there is an old file still there which gets used


printf "\n***  /home/dante/dantescript/copy-out.sh: cleaning up old stuff..LS-LA.\n "
  ls -la /mnt/${TARGET}
  exec 1>&1 2>&2
printf "DONE cleaning up old stuff\n"


printf "\n***  /home/dante/dantescript/copy-out.sh: cleaning up old stuff..LS-LD.\n "
  ls -ld /mnt/${TARGET}
  exec 1>&1 2>&2
printf "DONE cleaning up old stuff\n"

## copy out what we have just produced from 
printf "\n\n***  /home/dante/dantescript/copy-out.sh: copying out...\n"
  cp -a ${MOUNT}/${TARGET} /mnt
  cp -a ${MOUNT}/index.html /mnt
  exec 1>&1 2>&2
printf "DONE cleaning up old stuff\n"

printf "\n***  /home/dante/dantescript/copy-out.sh: doing an LS-LA after the copying operation \n "
  ls -la /mnt/${TARGET}
  exec 1>&1 2>&2
printf "DONE cleaning up old stuff\n"




printf "*** /home/dante/dantescript/copy-out.sh has completed. GOOD BYE\n"
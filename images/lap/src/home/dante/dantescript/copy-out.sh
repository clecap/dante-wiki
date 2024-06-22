#!/bin/bash

# This entrypoint initializes the database, generates LocalSettings.php and runs update.php


printf "\n\n*** THIS IS /home/dante/dantescript/copy-out.sh *****\n\n "


### set terminate on error 
#abort()
#{
#  printf "%b" "\e[1;31m *** *** *** ABORTED *** *** *** \e[0m"
#  exit 1
#}
#set -e                                  # abort execution on any error
#trap 'abort' EXIT                       # call abort on EXIT

###### send mail upon completion ????
#### favicon must be included into the thing - and at the dockerfile level ## todo
#### check if we are already initialized ##### TODO
####### crontab entries for backup and for job queue TODO

MOUNT=/var/www/html/
TARGET=wiki-dir

rm -rf /mnt/info.php
rm -rf /mnt/index.html
rm -rf /mnt/${TARGET}

## copy out what we have just produced from 
cp -a ${MOUNT}/${TARGET} /mnt

printf "*** /home/dante/dantescript/copy-out.sh has completed and will now terminate. GOOD BYE\n\n"






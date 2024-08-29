#!/bin/bash

# This entrypoint initializes the database, generates LocalSettings.php and runs update.php

source /home/dante/dantescript/common-defs.sh

printf "${GREEN}*** THIS IS /dantescript/init.sh ***** ${RESET}"




touchLocalSettings

trap - ERR

printf "\n\n*** /home/dante/dantescript/init.sh COMPLETED \n\n"
#!/bin/bash

## THIS FILE is in dante-wiki and NOT in production !!

# get directory where this script resides wherever it is called from
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
TOP_DIR=${DIR}/.. 


USER=apache
# we need to run the maintenance scripts under the user under which the dante wiki is running normally in the server
# to get the correct permissions for later operations

LAP_CONTAINER=my-lap-container

DUMPFILE=/var/www/html/wiki-dir/minimal-initial-contents.xml
MAIN=/var/www/html/wiki-dir/minimal-initial-mainpage.wiki

printf "\n\n*** Initial contents will be uploaded to wiki"
printf "\n\n*** IGNORE THE 'Done!' messages, they do not apply"
printf "\n\n*** WAIT until we tell you that the content initialization is complete\n\n" 

### CAVE: this must run as user apache
printf "*** Doing namespace 8 \n"
  docker exec  --user ${USER} ${LAP_CONTAINER}  php /var/www/html/wiki-dir/maintenance/importDump.php --namespaces '8' --debug ${DUMPFILE}
printf "DONE namespaces 8\n\n"

printf "*** Doing namespace 10 \n"
  docker exec  --user ${USER} ${LAP_CONTAINER}  php /var/www/html/wiki-dir/maintenance/importDump.php --namespaces '10' --debug ${DUMPFILE}
printf "DONE namespaces 10\n\n"

printf "*** Doing the rest, but no uploads flag (takes long)\n"
  docker exec  --user ${USER} ${LAP_CONTAINER}  php /var/www/html/wiki-dir/maintenance/importDump.php --debug ${DUMPFILE}
printf "DONE rest, no upload flag\n\n"

printf "*** Doing the upload flag (takes long)\n" 
  docker exec  --user ${USER} ${LAP_CONTAINER}  php /var/www/html/wiki-dir/maintenance/importDump.php --uploads --debug ${DUMPFILE}
printf "DONE the upload flag\n\n"

printf "*** Loading initial main page\n" 
  docker exec  --user ${USER} ${LAP_CONTAINER}  php /var/www/html/wiki-dir/maintenance/importTextFiles.php ${MAIN}
printf "DONE loading initial main page\n\n"

printf "*** Running some maintenance commands\n"
  docker exec  --user ${USER} ${LAP_CONTAINER}  php /var/www/html/wiki-dir/maintenance/rebuildrecentchanges.php
  docker exec  --user ${USER} ${LAP_CONTAINER}  php /var/www/html/wiki-dir/maintenance/initSiteStats.php --update 
printf "DONE running some maintenance commands"


printf "\n\n*** THE CONTENT INITIALIZATION NOW IS COMPLETED \n\n"
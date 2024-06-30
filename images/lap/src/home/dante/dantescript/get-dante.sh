#!/bin/bash

source /home/dante/dantescript/common-defs.sh

#### TODO MUST ABORT COMPLETEL including upstream in case of error - also for some of the other dante scripts. and need an abotzt in lapentry-.sh

if [ -d "$MOUNT/$TARGET/.git" ]; then
    printf "\n*** get-dante.sh: Git directory ${MOUNT}/$TARGET/.git already exists ... doing a PULL \n"
      git -C ${MOUNT}/${TARGET} pull origin ${DANTE_BRANCH} ;       exec 1>&1 2>&2
    printf "DONE"
  else
    printf "\n*** get-dante.sh: Initialize a git...\n"
      git init ${MOUNT}/${TARGET} ;       exec 1>&1 2>&2
    printf "DONE"

    printf "\n*** get-dante.sh: remote add origin to dante-delta ...\n"
      git -C ${MOUNT}/${TARGET} remote add origin ${REMOTE_REPO_DANTE} ;       exec 1>&1 2>&2
    printf "DONE"

    printf "\n*** get-dante.sh: fetching dante-delta ...\n"
      git -C ${MOUNT}/${TARGET} fetch --depth 1 origin ${DANTE_BRANCH} ;       exec 1>&1 2>&2
    printf "DONE"

    printf "\n*** get-dante.sh:  checking out dante-delta ...\n"
      git -C ${MOUNT}/${TARGET} checkout -f -t origin/${DANTE_BRANCH};       exec 1>&1 2>&2
    printf "DONE"
## todo we might need to run update again, as the last time we did do so, the dante extensions had not been installed into LocalSettings.php yet
fi






##  installExtensionGithub https://github.com/wikimedia/mediawiki-extensions-DrawioEditor                   DrawioEditor REL1_39
## This extension is broken currently
##  Use my own version - see my mediawiki-extensions-DrawioEditor Patch
  /home/dante/dantescript/install-extension-github.sh  ${MAOUNT}/${TARGET}  https://github.com/clecap/mediawiki-extensions-DrawioEditor                      DrawioEditor                master && \
  wget https://raw.githubusercontent.com/clecap/mediawiki-extensions-DrawioEditor/master/PATCH-UploadedFile.php -O ${MOUNT}/$TARGET}/includes/libs/ParamValidator/Util/UploadedFile.php && \
  wget https://raw.githubusercontent.com/clecap/mediawiki-extensions-DrawioEditor/master/PATCH-UploadBase.php -O ${MOUNT}/$TARGET}includes/upload/UploadBase.php   && \






#   inject only, after LocalSettings.php has been generated
if [ -f "$MOUNT/$TARGET/LocalSettings.php" ]; then
    printf "\n*** get-dante.sh:  connecting to Mediawiki via an injection into LocalSettings.pgp ...\n"
    cat <<EOF >> ${MOUNT}/$TARGET/LocalSettings.php
###
### Automagically injected by volume cmd.sh 
###
require_once ("DanteSettings.php"); 
EOF
    printf "DONE"
  else
    printf "\n*** +++++++++++++++++++++++++++++ get-dante.sh: no LocalSettings.php found, cannot inject \n"
fi

if [ -f "$MOUNT/$TARGET/mediawiki-PRIVATE.php" ]; then
    printf "\n*** get-dante.sh: mediawiki-PRIVATE.php already existing, skip generation\n"
  else
    printf "\n*** get-dante.sh: mediawiki-PRIVATE.php not found, generating it...\n"
    cat <<EOF >> ${MOUNT}/$TARGET/mediawiki-PRIVATE.php
<?php

\$wgPasswordSender = "${SMTP_FROM}";          // address of the sending email account

\$wgSMTP = [
    'host'     => '${SMTP_HOST}',                // hostname of the smtp server of the email account
    'IDHost'   => '${MY_DOMAINNAME}',            // sub(domain) of your wiki
    'port'     => ${SMTP_PORT},                  // SMTP port to be used
    'username' => '${SMTP_USER}',                // username of the email account
    'password' => '${SMTP_PASSWORD}',            // password of the email account
    'auth'     => true                           // shall authentisation be used
];

\$wgLocaltimezone="${MW_TIMEZONE}";

\$DEEPL_API_KEY="${DEEPL_API_KEY}";

// AWS data for an S3 user restricted to backup   dantebackup.iuk.one
\$wgDefaultUserOptions['aws-accesskey']       =  '${AWS_ACCESS_KEY_ID}';
\$wgDefaultUserOptions['aws-secretaccesskey'] =  '${AWS_SECRET_ACCESS_KEY}';
\$wgDefaultUserOptions['aws-bucketname']      =  '${AWS_BUCKETNAME}';
\$wgDefaultUserOptions['aws-region']          =  '${AWS_DEFAULT_REGION}';
\$wgDefaultUserOptions['aws-encpw']           =  '${MY_AWS_CRYPTO_PASSWORD}';

?>
EOF
    printf "DONE generating mediawiki-PRIVATE.php"
fi





# trap : EXIT         # switch trap command back to noop (:) on EXIT
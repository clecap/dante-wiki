#!/bin/bash

source /home/dante/dantescript/common-defs.sh

loadSecrets

if [ -f "$MOUNT/$TARGET/mediawiki-PRIVATE.php" ]; then
    printf "\n${ERROR}*** get-dante.sh: mediawiki-PRIVATE.php already existing - will delete and regenerate${RESET}\n"
    rm ${MOUNT}/$TARGET/mediawiki-PRIVATE.php
    printf "   DONE deleting\n"
  else
    printf "\n*** get-dante.sh: mediawiki-PRIVATE.php not found - will generate one\n"
fi

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

?>
EOF

chmod 600 ${MOUNT}/$TARGET/mediawiki-PRIVATE.php
chown www-data:www-data 600 ${MOUNT}/$TARGET/mediawiki-PRIVATE.php

printf "DONE generating mediawiki-PRIVATE.php\n"


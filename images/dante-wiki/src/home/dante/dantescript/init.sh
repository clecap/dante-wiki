#!/bin/bash

# This entrypoint initializes the database, generates LocalSettings.php and runs update.php

source /home/dante/dantescript/common-defs.sh
loadSecrets                                       # lap-entrypoint.sh no longer loads the secrets for us

printf "${GREEN}*** THIS IS /dantescript/init.sh ***** ${RESET}\n"


##### TODO: below we only use MOUTN and not TARGET. Is that correct? everyhwere else we use both!

printf "\n*** init.sh: Copying /home/dante/html material to ${MOUNT}..."
  cp -r /home/dante/html/*    ${MOUNT}
printf "DONE\n\n"

# check if we already have a LocalSettings.php
if [ -e "${MOUNT}/${TARGET}/LocalSettings.php" ]; then
  printf "${GREEN} *** init.sh finds the system already in initialized state - exiting init.sh\n"
  exit 0
fi

####### crontab entries for backup and for job queue TODO:  add in different place in docker home part

printf  "*** CALLING MEDIAWIKI INSTALL ROUTINE maintenance/install.php -----------------\n "

# We run install.php as the installer user MY_DB_I_USER and do NOT pass --installdbuser:
# With --installdbuser, MysqlInstaller::setupUser tries to GRANT ALL PRIVILEGES to 'MY_DB_USER'@'MY_DB_HOST',
# which fails, since MY_DB_I_USER has no GRANT OPTION (and that account would be useless anyhow).
# The users and their privileges are set up by createDBandUsers (prepare-database.sh).
# Below, LocalSettings.php is switched to the restricted user MY_DB_USER for normal operation.
if ! php ${MOUNT}/${TARGET}/maintenance/install.php \
    --confpath        ${MOUNT}/${TARGET} \
    --dbname         "$MY_DB_NAME" \
    --dbport         "3306" \
    --dbserver       "$MY_DB_HOST" \
    --dbtype         "mysql" \
    --dbuser         "$MY_DB_I_USER" \
    --dbpass         "$MY_DB_I_PASS" \
    --server        "$MW_SITE_SERVER" \
    --scriptpath     "/${TARGET}" \
    --lang           "$MW_SITE_LANGUAGE" \
    --pass           "$WK_ADMIN_PASS" \
    "${MW_SITE_NAME}" \
    "$WK_ADMIN_USER"
then
  failed "maintenance/install.php failed"
fi

printf "${GREEN}*** maintenance/install.php completed \n"


# check if we succeeded to generate LocalSettings.php
if [ -e "${MOUNT}/${TARGET}/LocalSettings.php" ]; then
  printf "${GREEN}*** SUCCESS:  ${MOUNT}/${TARGET}/LocalSettings.php  generated${RESET}\n"
else
  printf "${ERROR}*** ERROR:  Could not generate ${MOUNT}/${TARGET}/LocalSettings.php - *** ABORTING${RESET}\n"
  exit -1
fi


# Append to LocalSettings.php what the install script does not generate:
#   - the database user for normal operation (install.php wrote the installer user)
#   - the reference to DanteSettings.php
#   - mail and timezone settings from the configuration
printf "*** Adding database user, DanteSettings.php reference and mail / timezone settings to LocalSettings.php ... "
cat <<EOF >> "${MOUNT}/${TARGET}/LocalSettings.php" || failed "could not add database user, DanteSettings.php reference and settings to LocalSettings.php"

###
### Injected by /home/dante/dantescript/init.sh
###

// overrides the installer user written by install.php above
\$wgDBuser     = $(phpQuote "${MY_DB_USER}");
\$wgDBpassword = $(phpQuote "${MY_DB_PASS}");

require $(phpQuote "${MOUNT}/${TARGET}/DanteSettings.php");

\$wgPasswordSender = $(phpQuote "${SMTP_FROM}");          // address of the sending email account

\$wgSMTP = [
    'host'     => $(phpQuote "${SMTP_HOST}"),                // hostname of the smtp server of the email account
    'IDHost'   => $(phpQuote "${MY_DOMAINNAME}"),            // sub(domain) of your wiki
    'port'     => ${SMTP_PORT},                              // SMTP port to be used
    'username' => $(phpQuote "${SMTP_USER}"),                // username of the email account
    'password' => $(phpQuote "${SMTP_PASSWORD}"),            // password of the email account
    'auth'     => true                                       // shall authentication be used
];

\$wgLocaltimezone = $(phpQuote "${MW_TIMEZONE}");

EOF
printf "DONE\n"


# overwrite the default main page and sidebar from mediawiki by the default initial-content from dantewiki
# this also needs an --overwrite flag
printf "\n*** Checking in sidebar..."
  php ${MOUNT}/${TARGET}/maintenance/importTextFiles.php --rc -s "Imported by wiki-init.sh" --overwrite --prefix "MediaWiki:" "$CONT/Sidebar" \
    || failed "importing $CONT/Sidebar failed"
printf "DONE\n"

printf "\n*** Checking in MainPage..."
  php ${MOUNT}/${TARGET}/maintenance/importTextFiles.php --rc -s "Imported by wiki-init.sh" --overwrite  "$CONT/Main Page" \
    || failed "importing $CONT/Main Page failed"
printf "DONE\n"


# Must do an update, since we have installed all kinds of extensions earlier
doMaintenanceUpdate || failed "maintenance/update.php failed"

printf "\n\n*** /home/dante/dantescript/init.sh COMPLETED \n\n"
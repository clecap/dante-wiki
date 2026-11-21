#!/bin/bash

# This entrypoint initializes the database, generates LocalSettings.php and runs update.php  TODO: that is not completely correct here !

# This script checks if 

source /home/dante/dantescript/common-defs.sh
loadSecrets                                       # lap-entrypoint.sh no longer loads the secrets for us

printf "${GREEN}*** THIS IS /dantescript/init.sh ***** ${RESET}\n"




printf "\n*** init.sh: Copying /home/dante/html material to the overall web-root ${MOUNT}..."
  cp -r /home/dante/html/*    ${MOUNT}
printf "DONE\n\n"

# check if we already have a LocalSettings.php
if [ -e "${MOUNT}/${TARGET}/LocalSettings.php" ]; then
  printf "${GREEN} *** init.sh finds the system already in initialized state - exiting init.sh\n"
  exit 0
fi

####### crontab entries for backup and for job queue TODO:  add in different place in docker home part

printf  "*** CALLING MEDIAWIKI INSTALL ROUTINE maintenance/install.php -----------------\n "

# Database users: this deliberately differs from the MediaWiki documentation. See doc/README-user-concepts.md
#
# MediaWiki's model: the installer runs as root, creates the wiki user and grants it ALL PRIVILEGES on the wiki database.
# Our model: createDBandUsers (prepare-database.sh) creates both users beforehand; the installer user MY_DB_I_USER
#   may change the schema but has no GRANT OPTION, the runtime user MY_DB_USER may only read and write data.
#
# The documented call (--installdbuser MY_DB_I_USER --dbuser MY_DB_USER) fails here: --installdbuser switches on
# account creation, and MysqlInstaller::setupUser then issues GRANT ALL PRIVILEGES to 'MY_DB_USER'@'MY_DB_HOST'.
# That GRANT is refused (no GRANT OPTION, account does not exist), counts as fatal and aborts the installation;
# if it succeeded, it would remove the restriction on MY_DB_USER.
#
# Workaround: we pass MY_DB_I_USER as --dbuser and no --installdbuser. Install user and runtime user are then
# identical, setupUser returns without creating or granting anything, and the tables are created as MY_DB_I_USER.
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
  failed "*** ERROR:  Could not generate ${MOUNT}/${TARGET}/LocalSettings.php - *** ABORTING\n"
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

// overrides the installer user written by install.php above (see doc/README-user-concepts.md)
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
  php ${MOUNT}/${TARGET}/maintenance/importTextFiles.php --rc -s "Imported by init.sh" --overwrite --prefix "MediaWiki:" "$CONT/Sidebar" \
    || failed "importing $CONT/Sidebar failed"
printf "DONE\n"

printf "\n*** Checking in MainPage..."
  php ${MOUNT}/${TARGET}/maintenance/importTextFiles.php --rc -s "Imported by init.sh" --overwrite  "$CONT/Main Page" \
    || failed "importing $CONT/Main Page failed"
printf "DONE\n"


# Must do an update, since we have installed all kinds of extensions earlier
doMaintenanceUpdate || failed "maintenance/update.php failed"

printf "\n\n*** /home/dante/dantescript/init.sh COMPLETED \n\n"
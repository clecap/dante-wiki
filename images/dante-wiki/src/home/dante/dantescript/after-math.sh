#!/bin/bash

# after-math performs a re-imprinting of an already completely installed raw DanteWiki container to a new set of personalizations

if [ -e ${MOUNT}${TARGET}/NO-LONGER-A-STEMCELL ]; then
  printf "${GREEN} *** We are no longer a stemcell, skipping after-amth.sh\n${RESET}"
  exit 0
fi



loadSecrets


###### TODO: we should not place all these values into the log !!!!! secrets !!!!

printf "*** Editing \$wgSitename to $MW_SITE_NAME\n"
  sed -i.bak "s/\(\$wgSitename\s*=\s*\).*\$/\1\"$MW_SITE_NAME\";/" "${MOUNT}${TARGET}/LocalSettings.php"
  if [ $? -eq 0 ]; then
    printf "*** \$wgSitename successfully changed to '$MW_SITE_NAME'."
    printf "A backup of the original LocalSettings.php has been saved as LocalSettings.php.bak"
  else
    printf "${ERROR}Error: Failed to change \$wgSitename\n\n"
    exit 1
  fi


printf "*** Editing \$wgServer to $MW_SITE_SERVER\n"
  sed -i.bak "s/\(\$wgServer\s*=\s*\).*\$/\1\"$MW_SITE_SERVER\";/" "${MOUNT}${TARGET}/LocalSettings.php"
  if [ $? -eq 0 ]; then
    printf "*** \$wgServer successfully changed to '$MW_SITE_SERVER'."
    printf "A backup of the original LocalSettings.php has been saved as LocalSettings.php.bak"
  else
    printf "${ERROR}Error: Failed to change \$wgServer\n\n"
    exit 1
  fi


printf "*** Editing \$wgDBpassword to $MY_DB_PASS\n"
  sed -i.bak "s/\(\$wgDBpassword\s*=\s*\).*\$/\1\"$MY_DB_PASS\";/" "${MOUNT}${TARGET}/LocalSettings.php"
  if [ $? -eq 0 ]; then
    printf "*** \$wgDBpassword successfully changed to '$MY_DB_PASS'."
    printf "A backup of the original LocalSettings.php has been saved as LocalSettings.php.bak"
  else
    printf "${ERROR}Error: Failed to change \$wgDBpassword\n\n"
    exit 1
  fi


printf "Generating a 64-bit random key using MWCryptRand::generateHex in PHP\n"
  secret_key=$(php -r "require_once '{MOUNT}${TARGET}/includes/libs/crypto/MWCryptRand.php'; echo MWCryptRand::generateHex(64);")
  printf "Replacing the wgSecretKey line in LocalSettings.php with the new key\n"
  sed -i "s/^\$wgSecretKey=.*;/\$wgSecretKey = \"$secret_key\";/" ${MOUNT}${TARGET}/LocalSettings.php



printf "Generating a 64-bit random key using MWCryptRand::generateHex in PHP\n"
  upgrade_key=$(php -r "require_once '{MOUNT}${TARGET}/includes/libs/crypto/MWCryptRand.php'; echo MWCryptRand::generateHex(64);")
  printf "Replacing the wgUpgradeKey line in LocalSettings.php with the new key\n"
  sed -i "s/^\$wgUpgradeKey=.*;/\$wgUpgradeKey = \"$upgrade_key\";/" ${MOUNT}${TARGET}/LocalSettings.php


generate-mediawiki-private.sh
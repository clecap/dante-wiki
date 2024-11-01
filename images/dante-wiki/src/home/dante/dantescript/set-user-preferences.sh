#!/bin/bash

# This entrypoint initializes the database, generates LocalSettings.php and runs update.php

source /home/dante/dantescript/common-defs.sh

printf "${GREEN}*** THIS IS set-user-preferences.sh ***** ${RESET}"

loadSecrets
export MYSQL_PWD="${MYSQL_ROOT_PASSWORD}"

trap warn ERR

##
## Define a shorthand for setting preferences
##
setPref()
{
  local key=$1
  local value=$2
  setUserPreference "${MY_DB_HOST}" "${MY_DB_NAME}" "Admin" ${key} ${value}
}


##
## AWS S3 Backup System Configuration
##
setPref "aws-accesskey"                "${AWS_ACCESS_KEY_ID}"
setPref "aws-secretaccesskey"          "${AWS_SECRET_ACCESS_KEY}"
setPref "aws-region"                   "${AWS_DEFAULT_REGION}"
setPref "aws-bucketname"               "${AWS_BUCKETNAME}"
setPref "aws-encpw"                    "${MY_AWS_CRYPTO_PASSWORD}"

##
## SSH Based Backup System Configuration
##
setPref 'ssh-host'           "${SSH_HOST}"
setPref 'ssh-dump-user'      "${SSH_DUMP_USER}"
setPref 'ssh-dump-pw'        "${SSH_DUMP_PW}"
setPref 'ssh-restore-user'   "${SSH_RESTORE_USER}"
setPref 'ssh-restore-pw'     "${SSH_RESTORE_PW}"
setPref 'ssh-encpw'          "${SSH_ENCPW}"

##
## Passwords for local backup encryption
##
setPref 'ssh-encpw'          "${SSH_ENCPW}"


##
## Other API keys
##
setPref "pref-deepl-api-key"             "${DEEPL_API_KEY}"
setPref "pref-openai-organization-key"   "${OPENAI_ORGANIZATION_KEY}"
setPref "pref-openai-api-key"            "${OPENAI_API_KEY}"

setPref "github-dante-wiki-contents"     "${GITHUB_DANTE_WIKI_CONTENTS}"



printf "*** Editing \$danteConfigurationHash to $DANTE_CONFIG_HASH\n"
  sed -i.bak "s/\(\$danteConfigurationHash\s*=\s*\).*\$/\1\"$DANTE_CONFIG_HASH\";/" "${MOUNT}${TARGET}/DanteSettings.php"
  if [ $? -eq 0 ]; then
    printf "*** \$danteConfigurationHash successfully changed to '$DANTE_CONFIG_HASH'."
    printf "A backup of the original DanteSettings.php has been saved as DanteSettings.php.bak\n"
  else
    printf "${ERROR}Error: Failed to change \$danteConfigurationHash\n\n${RESET}"
    exit 1
  fi


# clear mysql root password again
export MYSQL_PWD=""

#!/bin/bash

# This entrypoint initializes the database, generates LocalSettings.php and runs update.php

source /home/dante/dantescript/common-defs.sh

printf "${GREEN}*** THIS IS set-user-preferences.sh ***** ${RESET}"

set -e; trap 'abort' ERR

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

trap - ERR
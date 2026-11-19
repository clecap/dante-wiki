#!/bin/bash

source /home/dante/dantescript/common-defs.sh

set -e

# must load the secrets and export password into child processes since mysql will run in a child process
loadSecrets
export MYSQL_PWD="${MYSQL_ROOT_PASSWORD}"

# This script downloads an sql file and uses it to restore the database from it.
#
# If $1 is URL then download the file using curl,        using $2 as URL
# If $1 is S3  then download the file using aws s3 cp,   using $2 as URL 
#
# After a successful restore a marker file is generated.
# Before the restore, the existence of the marker file is tested.
# If the marker file exists, the restore is skipped - unless parameter $3 is given and equals force.
#



SOURCE=${INITIAL_DATABASE_SOURCE}
LOCATION=${INITIAL_DATABASE_SPECIFICATION}

#SOURCE=$1
#LOCATION=$2
#FORCE=${3:-}



[ -n "${LOCATION}" ] || failed "missing location (URL) as parameter 2"

RESTORE_MARKER="${MOUNT}.dante-db-restored-${MY_DB_NAME}"

if [ -f "${RESTORE_MARKER}" ] && [ "${FORCE}" != "force" ]; then
  printf "*** Database ${MY_DB_NAME} already restored on $(cat "${RESTORE_MARKER}"), skipping restore\n"
  exit 0
fi

# download command which writes the file to stdout
case "${SOURCE}" in
  URL)  FETCH=(curl -fsSL "${LOCATION}") ;;
  S3)   FETCH=(aws s3 cp "${LOCATION}" -) ;;   # credentials from AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_DEFAULT_REGION
  *)    failed "parameter 1 must be URL or S3, but is '${SOURCE}'" ;;
esac

printf "*** Restoring database ${MY_DB_NAME} from ${SOURCE} ${LOCATION}\n"
set -o pipefail
"${FETCH[@]}" | { [[ "${LOCATION}" == *.gz ]] && gunzip -c || cat; } | mysql -h ${MY_DB_HOST} -u root --skip-ssl --default-character-set=binary ${MY_DB_NAME} || failed "restoring database ${MY_DB_NAME} from ${SOURCE} ${LOCATION}"
printf "$(date -Iseconds) from ${SOURCE} ${LOCATION}\n" > "${RESTORE_MARKER}"
printf "*** DONE restoring database ${MY_DB_NAME}\n"



set +e

printf "\n*** restored from initial database \n"


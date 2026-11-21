#!/bin/bash

source /home/dante/dantescript/common-defs.sh

set -e

# must load the secrets and export password into child processes since mysql will run in a child process
loadSecrets
export MYSQL_PWD="${MYSQL_ROOT_PASSWORD}"


# This script downloads two sql files and restores them into database MY_DB_NAME, one after the other:
#   1. the initial tables
#   2. the user data
#
# Source and location are taken from the configuration:
#   initial tables:  INITIAL_DATABASE_SOURCE, INITIAL_DATABASE_SPECIFICATION
#   user data:       USER_DATA_SOURCE,        USER_DATA_SPECIFICATION
# If the respective _SOURCE variable is URL then download the file using curl,       from the specification as URL
# If the respective _SOURCE variable is S3  then download the file using aws s3 cp,  from the specification as S3 URL
# If the respective _SOURCE is the empty string, then do nothing.
# A file name ending in .gz is unzipped before the restore.
#
# Each restore happens only once per database (restoreDatabaseOnce in common-defs.sh): after a successful restore
# its marker (initial-tables-restored, user-data-restored) is set in database MY_DB_NAME, and if the marker exists, that
# restore is skipped. If the check itself fails, the script aborts instead of restoring blindly.
# The marker lives in the database itself, so it shares the lifetime of the database volume and not of the
# wiki container: a new wiki container on a kept volume skips the restore, a new (empty) volume restores again.
#

if [ -z "${INITIAL_DATABASE_SOURCE}" ]; then
  printf "*** INITIAL_DATABASE_SOURCE is empty, not restoring initial tables\n"
else
  [ -n "${INITIAL_DATABASE_SPECIFICATION}" ] || failed "INITIAL_DATABASE_SPECIFICATION (location of the sql file) is empty or not set in configuration"
  restoreDatabaseOnce "${MY_DB_HOST}" "${MY_DB_NAME}" "initial-tables-restored" "${INITIAL_DATABASE_SOURCE}" "${INITIAL_DATABASE_SPECIFICATION}" "initial tables"
fi

if [ -z "${USER_DATA_SOURCE}" ]; then
  printf "*** USER_DATA_SOURCE is empty, not restoring user data\n"
else
  [ -n "${USER_DATA_SPECIFICATION}" ] || failed "USER_DATA_SPECIFICATION (location of the sql file) is empty or not set in configuration"
  restoreDatabaseOnce "${MY_DB_HOST}" "${MY_DB_NAME}" "user-data-restored" "${USER_DATA_SOURCE}" "${USER_DATA_SPECIFICATION}" "user data"
fi

set +e

printf "\n*** restore-from-database.sh completed \n"


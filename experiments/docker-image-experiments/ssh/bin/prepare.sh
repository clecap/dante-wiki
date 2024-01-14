#!/bin/bash
#
#
# generate a universal public, private key pair that we shall use for logging in into EVERY container running this image

# get directory this shell is running in
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source ${DIR}/PARAMETERS.sh

# cleaning up
rm -f ${DIR}/../login-key ${DIR}/../login-key.pub ${DIR}/../src/login-key.pub ${DIR}/../../../conf/login-key

# generate login-key and login-key.pub without a protection by a pass phrase
ssh-keygen -N "" -f ${DIR}/../login-key

# fix permissions
chmod 0400 ${DIR}/../login-key

# copy the PUBLIC key into the docker context area
cp ${DIR}/../login-key.pub ${DIR}/../src

# copy the PRIVATE key into the conf directory of the entire project
cp ${DIR}/../login-key ${DIR}/../../../conf/login-key
chmod 0400 ${DIR}/../../../conf/login-key

printf "** Removing entries for localhost in known_hosts, error 'not found' is ok..."
ssh-keygen -R localhost
printf "DONE removing entries for localhost"
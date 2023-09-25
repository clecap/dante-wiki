#!/bin/bash

# configures the local user for 

# get directory this shell is running in
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source ${DIR}/PARAMETERS.sh

printf "** Removing possible old fingerprints for localhost..."
ssh-keygen -R localhost
printf "DONE removing\n"

printf "** Retrieving public hostkey from container to local..."
docker cp ${CONTAINER_NAME}:/etc/ssh/ssh_host_rsa_key.pub .
printf "DONE retrieveing\n"

printf "** Adding hostkey to list of known hosts at ${HOME}..."
echo "localhost " `cat ${DIR}/ssh_host_rsa_key.pub` >>  ${HOME}/.ssh/known_hosts
printf "DONE adding\n"

printf "** Doing local cleanup..."
rm ${DIR}/../ssh_host_rsa_key.pub
printf "DONE local cleanup\n"

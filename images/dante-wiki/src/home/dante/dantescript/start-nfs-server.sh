#!/bin/bash

source /home/dante/dantescript/common-defs.sh

printf "*** THIS IS start-nfs-server.sh\n\n"


trap warn ERR

printf "** Starting rpcbind..." 
rpcbind 
printf "DONE starting rpcbind\n"

printf "** Starting to export..."
exportfs -r 
printf "DONE starting to export\n"

printf "** Starting rpc.statd..."
rpc.statd
printf "DONE starting rpc.statd\n"

printf "** Starting rpc.nfsd..."
rpc.nfsd 
printf "DONE starting rpc.nfsd\n"

printf "** Starting nfsd..."
nfsd 
printf "DONE starting nfsd\n"

#  chown -R www-data:www-data ${MOUNT}/${TARGET} ; exec 1>&1 2>&2
printf "DONE chowning all files\n"

trap abort ERR

printf "${GREEN}*** EXITING chown.sh\n\n"
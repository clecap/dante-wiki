#!/bin/bash


# Stop the webserver 

CONTAINER_NAME=my-lap-container

# get directory where this script resides wherever it is called from
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"


# kill httpd daemon
docker exec ${CONTAINER_NAME} killall httpd


docker cp ${DIR}/../src/etc/apache2/httpd-common.conf   ${CONTAINER_NAME}:/etc/apache2
docker cp ${DIR}/../src/etc/apache2/httpd-FPM.conf   ${CONTAINER_NAME}:/etc/apache2
docker cp ${DIR}/../src/etc/apache2/httpd-mediawiki.conf   ${CONTAINER_NAME}:/etc/apache2
docker cp ${DIR}/../src/etc/apache2/httpd-PHP.conf   ${CONTAINER_NAME}:/etc/apache2
docker cp ${DIR}/../src/etc/apache2/ssl.conf   ${CONTAINER_NAME}:/etc/apache2

docker cp ${DIR}/../src/etc/apache2/httpd.conf   ${CONTAINER_NAME}:/etc/apache2




docker exec ${CONTAINER_NAME} /apache-php-fpm-entry.sh


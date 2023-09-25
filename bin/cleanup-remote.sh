#!/bin/bash

printf "*** Stopping lap and mysql images and removing them - takes a while \n\n"

docker stop my-lap-container
docker rm my-lap-container
docker stop my-mysql
docker rm my-mysql

docker volume rm my-test-db-volume
docker volume rm sample-volume

printf "\n\nDONE"


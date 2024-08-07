#!/bin/bash

source /home/dante/dantescript/common-defs.sh

printf "\n*** *** *** THIS IS /home/dante/dantescript/job-queue.sh ***** "



# Put the MediaWiki installation path on the line below
MW_INSTALL_PATH="/home/www/www.mywikisite.example/mediawiki"
RUN_JOBS="$MW_INSTALL_PATH/maintenance/runJobs.php --maxtime=3600"

# Wait a minute after the server starts up to give other processes time to get started
sleep 60
printf "Starting job service..."

while true; do
	# Job types that need to be run ASAP no matter how many of them are in the queue
	# Those jobs should be very "cheap" to run
	php $RUN_JOBS --type="enotifNotify"
	# Everything else, limit the number of jobs on each batch
	# The --wait parameter will pause the execution here until new jobs are added,
	# to avoid running the loop without anything to do
	php $RUN_JOBS --wait --maxjobs=20
	# Wait some seconds to let the CPU do other things, like handling web requests, etc
	echo Waiting for 10 seconds...
	sleep 10
done
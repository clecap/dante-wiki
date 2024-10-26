#!/bin/bash

# TODO: USE branches in github and tags in docker hub !!!

# branch we are checking out from github
BRANCH=master



upServices $TOP_DIR/composer/docker-compose-development.yaml database webserver-raw phpmyadmin


waitForWebserverServicing
openChrome
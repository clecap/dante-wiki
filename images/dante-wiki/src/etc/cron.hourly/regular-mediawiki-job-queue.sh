#!/bin/sh

# When moving to mediawiki 1.40 we must change this, see https://www.mediawiki.org/wiki/Manual:RunJobs.php

source /run/secrets/configuration 

/usr/bin/php /var/www/html/${PREFIX}/maintenance/runJobs.php --maxtime=3600 > /var/log/runJobs.log 2>&1

#!/bin/sh

# activate /etc/backup/backup-script.sh

##
## PARAMETERS supplied to the script:
##
# MODE   Parameter 1:  Which backup to generate.              Values:   sql    or  xml
# TRANS  Parameter 2:  How to transport to the backup place.  Values:   rsync  or  ssh_stream  (or aws_stream, github_stream and more)
# FREQ   Parameter 3:  Identifies time stamp and kind of the dump. Eg: week-10  day-2024-07-28  or similar

/etc/backup/backup-script.sh sql rsync day "day_$(date +'%Y-%m-%d_%H-%M-%S')"
/etc/backup/backup-script.sh xml ssh_stream day "day_$(date +'%Y-%m-%d_%H-%M-%S')"

#!/bin/sh



source main-config.sh

### TODO warning if missing


MAIL=$1
FROM=$2
SOURCE_NAME=$3
TARGET_USER=$4
TARGET_HOST=$5

MODE="dumpPagesBySsh"     

## the command which generates a stream of contents
COMMAND="php /var/www/html/${PREFIX}/maintenance/dumpBackup.php --full --include-files --uploads"

# Directory prefix for the wiki directory inside of the container
PREFIX=wiki-dir

# Subject of email
SUBJECT="Report on dump of DanteWiki ${PREFIX} to ${TARGET_HOST} via ${DROP}"

# Name of the
DUMP_FILE_NAME="wiki-xml-dump-$(date +%d.%m.%y).xml"

# Name of a temporary file for building up the mail
TMPFILE=`mktemp`
TMPFILE2=`mktemp`

DUMPUSER=backmeup

# generate header in mail file
echo "To: $MAIL"         >> $TMPFILE
echo "From: $FROM"       >> $TMPFILE
echo "Subject: $SUBJECT" >> $TMPFILE

case "$MODE" in
  "dumpPagesBySsh")
    echo "backup.sh: Generating dump files via $MODE" >> $TMPFILE
    echo "" >> $TMPFILE
    $COMMAND | ssh -o ServerAliveInterval=240 ${TARGET_USER}@${TARGET_HOST} ${DUMP_FILE_NAME} >> $TMPFILE 2>>$TMPFILE2
    echo "" >> $TMPFILE
    echo "backup.sh: Done generating dump files" >> $TMPFILE
    echo "" >> $TMPFILE
    echo "backup.sh: stderr of ssh is:" >> $TMPFILE
    cat $TMPFILE2 >> $TMPFILE
    ;;
  "aws")
    echo "AWS not yet implemented " >> $TMPFILE
    ;;
  *)
    echo "Unknown drop mode: $DROP" >> $TMPFILE
    ;;
esac


echo "Done dumping, now sending email"

# dispatch email

msmtp $MAIL < $TMPFILE

echo "Sent email"
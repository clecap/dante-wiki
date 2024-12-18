#!/bin/sh

#
# Script which will be used inside of the container of a containerized DanteWiki to generate regular backups
# and send information on this to the intended user
#

##
## PARAMETERS supplied to the script:
##
# MODE   Parameter 1:  Which backup to generate.              Values:   sql    or  xml
# TRANS  Parameter 2:  How to transport to the backup place.  Values:   rsync  or  ssh_stream  (or aws_stream, github_stream and more)
# FREQ   Parameter 3:  Identifies time stamp and kind of the dump. Eg: week-10  day-2024-07-28  or similar

MODE="$1"
TRANS="$2"
FREQ="$3"

source /run/secrets/configuration 

export MYSQL_PWD="${MYSQL_ROOT_PASSWORD}"

# The acronym for identification is the site name with spaces replaced by underscores 
ACRO="${MW_SITE_NAME// /_}"

# define flag which catches if there was just any error along this script - needed for proper subjectline in email
ERRORFLAG=0

# generate the name of the file as it then will appear in the backup storage
if [[ "$MODE" == "xml" ]]; then
  DUMPFILENAME="$ACRO-$FREQ.xml"
elif [[  "$MODE" == "sql" ]]
  DUMPFILENAME="$ACRO-$FREQ.sql"
else
  printf "\n Error: Illegal value for mode parameter found was: $MODE\n" >> $TMPFILE
  ERRORFLAG=1
fi

rm -f $DUMPFILENAME

# Name of a temporary file for building up the mail
TMPFILE=$(mktemp --suffix='.backupmail.txt')

# Name of temporary files capturing stderr in case of a pipe scenario
ONEERR=$(mktemp --suffix='.backup-one.log')
TWOERR=$(mktemp --suffix='.backup-two.log')

printf "/etc/backup/backup-driver.sh: Generating $MODE dump and sending via $TRANS for $ACRO, frequency $FREQ\n\n" >> $TMPFILE

if   [[ "$MODE" == "xml" && "$TRANS" == "ssh_stream" ]]; then
  printf "DOING xml/ssh_stream\n\n" >> $TMPFILE
    (php /var/www/html/${PREFIX}/maintenance/dumpBackup.php --full --include-files --uploads  2> $ONEERR) | (ssh -o ServerAliveInterval=240 ${CBB_TARGET_SSH_USER}@${CBB_TARGET_SSH_HOST} ${DUMPFILENAME} 2> $TWOERR)
    PHP_STATUS=${PIPESTATUS[0]}
    SSH_STATUS=${PIPESTATUS[1]}
    ERRORFLAG=$(( PHP_STATUS || SSH_STATUS || ERRORFLAG ))
    printf "\nSTATUS: PHP=$PHP_STATUS  SSH=$SSH_STATUS  TOTAL=$ERRORFLAG\n\n" >> $TMPFILE
    printf "\n\n*** PHP STDERR: \n" >> $TMPFILE
    cat $ONEERR >> $TMPFILE
    printf "\n\n*** SSH STDERR: \n" >> $TMPFILE
    cat $TWOERR >> $TMPFILE
  printf "\nDONE xml/ssh_stream\n\n" >> $TMPFILE 
elif [[ "$MODE" == "xml" && "$TRANS" == "rsync" ]]; then
  printf "DOING xml/rsync \n\n" >> $TMPFILE
  printf "First: generating xml into $DUMPFILENAME\n\n" >> $TMPFILE
    php /var/www/html/${PREFIX}/maintenance/dumpBackup.php --full --include-files --uploads > $DUMPFILENAME 2>> $TMPFILE
    XML_STATUS=$?
    ERRORFLAG==$(( XML_STATUS || ERRORFLAG ))
    printf "\nSTATUS: XML=$XML_STATUS TOTAL=$ERRORFLAG\n\n"
    printf "DONE generating xml" >> $TMPFILE
  printf "Second: rsyncing $DUMPFILENAME to $CBB_TARGET_SSH_HOST:$CBB_TARGET_SSH_PATH\n\n" >> $TMPFILE
    rsync -av -e "ssh " $DUMPFILENAME $CBB_TARGET_SSH_HOST:$CBB_TARGET_SSH_PATH   2>>  $TMPFILE
    RSYNC_STATUS=$?
    ERRORFLAG==$(( RSYNC_STATUS || ERRORFLAG ))
  printf "\nSTATUS: RSYNC=$RSYNC_STATUS TOTAL=$ERRORFLAG\n\n"
  printf "\nDONE rsync\n" >> $TMPFILE
elif [[ "$MODE" == "sql" && "$TRANS" == "ssh_stream" ]]; then
  printf "DOING sql and ssh_stream in one command \n\n" >> $TMPFILE
    (mysqldump --all-databases --routines --user=root 2>$ONEERR) | (ssh -o ServerAliveInterval=240 ${CBB_TARGET_SSH_USER}@${CBB_TARGET_SSH_HOST} ${DUMPFILENAME} 2> $TWOERR)
    SQL_STATUS=${PIPESTATUS[0]}
    SSH_STATUS=${PIPESTATUS[1]}
    ERRORFLAG=$(( SQL_STATUS || SSH_STATUS || ERRORFLAG ))
    printf "\nSTATUS: SQL=$SQL_STATUS  SSH=$SSH_STATUS  TOTAL=$ERRORFLAG\n\n"
    printf "\n\n*** SQL STDERR: \n" >> $TMPFILE
    cat $ONEERR >> $TMPFILE
    printf "\n\n*** SSH STDERR: \n" >> $TMPFILE
    cat $TWOERR >> $TMPFILE
  printf "\nDONE" >> $TMPFILE 
elif [[ "$MODE" == "sql" && "$TRANS" == "rsync" ]]; then
  printf "DOING sql/rsync \n\n" >> $TMPFILE
  printf "First: Generating sql into $DUMPFILENAME\n\n"
    mysqldump --all-databases --routines --user=root --result-file=$DUMPFILENAME >>  $TMPFILE
    SQL_STATUS=$?
    ERRORFLAG==$(( SQL_STATUS || ERRORFLAG ))
  printf "\nSTATUS: SQL=$SQL_STATUS TOTAL=$ERRORFLAG\n\n"
  printf "DONE sql" >> $TMPFILE
  printf "Second rsyncing $DUMPFILENAME to $CBB_TARGET_SSH_HOST:$CBB_TARGET_SSH_PATH\n\n" >> $TMPFILE
    rsync -av -e "ssh " $DUMPFILENAME $CBB_TARGET_SSH_HOST:$CBB_TARGET_SSH_PATH   >>  $TMPFILE
    RSYNC_STATUS=$?
    ERRORFLAG==$(( RSYNC_STATUS || ERRORFLAG ))
  printf "\nSTATUS: RSYNC=$RSYNC_STATUS TOTAL=$ERRORFLAG\n\n"
  printf "DONE rsync\n" >> $TMPFILE
else
  printf "\n Error: Illegal parameters found $MODE, $TRANS"
  ERRORFLAG=1
fi

# rm -f $ONEERR
# rm -f $TWOERR

# set mail subject
if [[ $status -eq 0 ]]; then
  SUBJECT="Dump OK"
else
  SUBJECT="ERROR in Dump"
fi


##
## dispatch email
##
{
  echo "To: $SMTP_TO"
  echo "Subject: $SUBJECT"
  echo "From: $SMTP_FROM" 
  echo
  cat $TMPFILE
} | msmtp --host=$SMTP_HOST --port=$SMTP_PORT --auth=on --user=$SMTP_USER --passwordeval="echo $SMTP_PASSWORD" --tls=on --from=$SMTP_FROM  ${SMTP_TO}


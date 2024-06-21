#!/bin/bash


echo "*** This is /dante-mysql-entrypoint.sh"
echo " "

echo "*** /dante-mysql-entrypoint.sh sees the following secret files:"
ls -alg /run/secrets
echo ""
if [ -f "/run/secrets/configuration" ]; then
    printf "*** /dante-mysql-entrypoint.sh will now load configuration..."
    source /run/secrets/configuration
    printf "DONE\n"
  else
    printf "\n*** ERROR: /dante-mysql-entrypoint.sh could not find configuration file, EXITING "
    exit 1
fi

# echo "*** /dante-mysql-entrypoint.sh sees the following configuration: "
## uncomment only for debugging - we do not want the private data to be in some log files
#echo "  MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD}"
#echo "  MY_DB_NAME: ${MY_DB_NAME}"
#echo "  MY_DB_USER: ${MY_DB_USER}"
#echo "  MY_DB_PASS: ${MY_DB_PASS}"


printf "\n***: /dante-mysql-entrypoint.sh: REGENERATE_PRIVATE_KEY is $REGENERATE_PRIVATE_KEY"

if [ "$REGENERATE_PRIVATE_KEY" = "true" ]; then
    echo "Environment variable requested us to regenerate the private key"
    rm -f /root/.ssh/id_rsa
    rm -f /root/.ssh/id_rsa.pub
    echo "  Existing keys removed"
    ssh-keygen -t rsa -b 4096 -f /root/.ssh/id_rsa -N ''
    echo "  New keys generated"
    # Name of a temporary file for building up the mail
    TMPFILE=`mktemp`
    # generate header in mail file
    ATTACHMENT="/root/.ssh/id_rsa.pub"
    BOUNDARY="ZZ_/afg6432dfgkl.94531q"
    {
      echo "To: $SMTP_TO"         >> $TMPFILE
      echo "From: $SMTP_FROM"       >> $TMPFILE
      echo "Subject: New private key for ssl backup host generated " >> $TMPFILE
      echo "MIME-Version: 1.0"
      echo "Content-Type: multipart/mixed; boundary=\"$BOUNDARY\""
      echo
      echo "--$BOUNDARY"
      echo "Content-Type: text/plain; charset=\"UTF-8\""
      echo "Content-Transfer-Encoding: 7bit"
      echo
      echo "This is the public key generated for the mysql container "
      echo 
      echo "Save the attached file (for example to /tmp/id_rsa.pub) and "
      echo "install it to the ssl backup host using "
      echo 
      echo "ssh-copy-id -i /tmp/id_rsa.pub  ${BACKUP_USER_SSL}@${BACKUP_HOST_SSL} "
      echo
      echo
      echo "--$BOUNDARY"
      echo "Content-Type: application/octet-stream; name=\"$(basename "$ATTACHMENT")\""
      echo "Content-Transfer-Encoding: base64"
      echo "Content-Disposition: attachment; filename=\"$(basename "$ATTACHMENT")\""
      echo
      base64 "$ATTACHMENT"
      echo
      echo "--$BOUNDARY--"
    } > $TMPFILE
    msmtp --host=${SMTP_HOST} --port=${SMTP_PORT} --auth=on --user=${SMTP_USER} --passwordeval="echo $SMTP_PASSWORD" --tls=on --from=${SMTP_FROM}  ${SMTP_TO} < $TMPFILE
    echo "  New key mailed"
  else
    echo "Environment variable did not request us to regenerate the private key"
fi



printf "\n\n*** /dante-mysql-entrypoint.sh now calling the original entrypoint of the basic docker file---------\n"

/usr/local/bin/docker-entrypoint.sh mysqld

printf "\n\n *** /dante-mysql-entrypoint.sh COMPLETED the original entrypoint of the basic docker file"
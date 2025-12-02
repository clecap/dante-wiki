#!/bin/bash

# Generates a (public, private) key pair for use in localhost
# Mails the public key to SMTP_TO
# Installs the public and private key
# 
# Installs the fingerprint of the ssh host locally

source /home/dante/dantescript/common-defs.sh

trap 'errorTrap' ERR

printf "*** This is install-webserver-certificate.sh\n"

if [ -e "/etc/ssl/apache2/server.crt" ] && [ -e "/etc/ssl/apache2/server.key" ]; then
  printf "/etc/ssl/apache2/server.crt and /etc/ssl/apache2/server.key both exist \n"
else
  printf "   One of /etc/ssl/apache2/server.crt or /etc/ssl/apache2/server.key both missing \n"
  APACHE_SERVER_KEY_LENGTH="${#APACHE_SERVER_KEY}"
  APACHE_SERVER_CRT_LENGTH="${#APACHE_SERVER_CRT}"
  printf "  APACHE_SERVER_KEY_LENGTH IS ${APACHE_SERVER_KEY_LENGTH}\n"
  printf "  APACHE_SERVER_CRT_LENGTH IS ${APACHE_SERVER_CRT_LENGTH}\n"
  if [ "$APACHE_SERVER_KEY_LENGTH" -gt 20 -a "$APACHE_SERVER_CRT_LENGTH" -gt 20 ]; then
    printf "*** install-webserver-certificate: Found certificate strings in secret, using them\n"
    printf "***KEY IS: ${APACHE_SERVER_KEY}\n"
    printf "***CRT IS: ${APACHE_SERVER_CRT}\n"
      sudo rm -f /etc/ssl/apache2/server.crt
      sudo rm -f /etc/ssl/apache2/server.key
      echo "${APACHE_SERVER_KEY}" > /tmp/server.key
      echo "${APACHE_SERVER_CRT}" > /tmp/server.crt
      sudo mv /tmp/server.key /etc/ssl/apache2/server.key
      sudo mv /tmp/server.crt /etc/ssl/apache2/server.crt
      sudo chmod 600 /etc/ssl/apache2/server.key
      sudo chmod 644 /etc/ssl/apache2/server.crt
    printf "DONE using secret strings\n"
  else
    printf "*** install-webserver-certificate: No reasonable strings found in secret, generating key and crt and mailing crt\n"
      openssl req -x509 -out /tmp/server.crt -quiet -keyout /tmp/server.key \
        -newkey rsa:2048 -nodes -sha256 \
        -days 900 \
        -subj '/CN=localhost' -extensions EXT -config <( \
      printf "[dn]\nCN=localhost\n[req]\ndistinguished_name = dn\n[EXT]\nsubjectAltName=DNS:localhost\nkeyUsage=digitalSignature\nextendedKeyUsage=serverAuth")

      exec 1>&1 2>&2

      sudo cp /tmp/server.crt /etc/ssl/apache2/server.crt
      sudo cp /tmp/server.key /etc/ssl/apache2/server.key
      rm /tmp/server.crt
      rm /tmp/server.key
      sudo chmod 600 /etc/ssl/apache2/server.key
      sudo chmod 644 /etc/ssl/apache2/server.crt

      # Name of a temporary file for building up the mail
      TMPFILE=`mktemp`
      # generate header in mail file
      ATTACHMENT="/etc/ssl/apache2/server.crt"
      BOUNDARY="ZZ_/afg6432dfgkl.94531q"
      {
        echo "To: $SMTP_TO"        
        echo "From: $SMTP_FROM"     
        echo "Subject: New certificate for dante site generated " 
        echo "MIME-Version: 1.0"
        echo "Content-Type: multipart/mixed; boundary=\"$BOUNDARY\""
        echo
        echo "--$BOUNDARY"
        echo "Content-Type: text/plain; charset=\"UTF-8\""
        echo "Content-Transfer-Encoding: 7bit"
        echo
        echo "This is the certificate generated for a dantewiki site running on localhost "
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
      printf "*** install-webserver-certificate: Made and mailed key and crt\n"
  fi
fi  


## echo "doing an ssh-keyscan for host ${SSH_HOST}"
## sudo ssh-keyscan ${SSH_HOST} >> /tmp/known_hosts
## sudo mv /tmp/known_hosts /root/.ssh/known_hosts


exec 1>&1 2>&2

trap - ERR

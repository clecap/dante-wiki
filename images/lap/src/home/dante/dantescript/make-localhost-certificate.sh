#!/bin/bash

# Generates a (public, private) key pair for use in localhost
# Mails the public key to SMTP_TO
# Installs the public and private key

source /home/dante/dantescript/common-defs.sh

set -e                                 # abort execution on any error
trap 'abort' ERR                       # call abort on error

printf "*** This is make-localhost-certificate.sh\n"

if [ -e "/etc/ssl/apache2/server.crt" ] && [ -e "/etc/ssl/apache2/server.key" ]; then
  printf "/etc/ssl/apache2/server.crt and /etc/ssl/apache2/server.key both exist \n"
else
  printf "   One of /etc/ssl/apache2/server.crt or /etc/ssl/apache2/server.key both missing \n"
  APACHE_SERVER_KEY_LENGTH="${#APACHE_SERVER_KEY}"
  APACHE_SERVER_CRT_LENGTH="${#APACHE_SERVER_CRT}"
  if [ "$APACHE_SERVER_KEY_LENGTH" -gt 20 && "$APACHE_SERVER_CRT_LENGTH" -gt 20 ]; then
    printf "*** make-localhost-certificate: Found certificate strings in secret, using them\n"
      rm -f /etc/ssl/apache2/server.crt
      rm -f /etc/ssl/apache2/server.key
      echo "$APACHE_SERVER_KEY" > /etc/ssl/apache2/server.key
      echo "$APACHE_SERVER_CRT" > /etc/ssl/apache2/server.crt
      chmod 600 /etc/ssl/apache2/server.key
      chmod 644 /etc/ssl/apache2/server.crt
    printf "DONE using secret strings\n"
  else
    printf "*** make-localhost-certificate: No reasonable strings found in secret, generating key and crt and mailing crt\n"
      openssl req -x509 -out /etc/ssl/apache2/server.crt -keyout /etc/ssl/apache2/server.key \
        -newkey rsa:2048 -nodes -sha256 \
        -subj '/CN=localhost' -extensions EXT -config <( \
      printf "[dn]\nCN=localhost\n[req]\ndistinguished_name = dn\n[EXT]\nsubjectAltName=DNS:localhost\nkeyUsage=digitalSignature\nextendedKeyUsage=serverAuth")
      chmod 600 /etc/ssl/apache2/server.key
      chmod 644 /etc/ssl/apache2/server.crt

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
      printf "*** make-localhost-certificae: Made and mailed key and crt\n"
  fi
fi  
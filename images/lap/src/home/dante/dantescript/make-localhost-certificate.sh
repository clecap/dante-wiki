#!/bin/bash

# Generates a (public, private) key pair for use in localhost
# Mails the public key to SMTP_TO
# Installs the public and private key



printf "*** This is make-localhost-certificate.sh"

if [ -e "/etc/ssl/apache2/server.crt" ] && [ -e "/etc/ssl/apache2/server.key" ]; then
  printf "/etc/ssl/apache2/server.crt and /etc/ssl/apache2/server.key both exist \n"
else

  printf "One of /etc/ssl/apache2/server.crt or /etc/ssl/apache2/server.key both missing, recreating \n"

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
      echo "To: $SMTP_TO"         >> $TMPFILE
      echo "From: $SMTP_FROM"       >> $TMPFILE
      echo "Subject: New certificate for dante site generated " >> $TMPFILE
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
    echo "  New key mailed"

fi

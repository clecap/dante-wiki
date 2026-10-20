#!/bin/bash

# make a webserver certificate for localhost

openssl req -x509 -out /tmp/server.crt -quiet -keyout /tmp/server.key \
  -newkey rsa:2048 -nodes -sha256 \
  -days 900 \
  -subj '/CN=localhost' -extensions EXT -config <( \
    printf "[dn]\nCN=localhost\n[req]\ndistinguished_name = dn\n[EXT]\nsubjectAltName=DNS:localhost\nkeyUsage=digitalSignature\nextendedKeyUsage=serverAuth")


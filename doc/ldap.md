



ldapsearch -x -H ldaps://ldap.uni-rostock.de -D "uid=cc007,ou=people,o=uni-rostock,c=de" -W




/etc/ldap/ldap.conf  auf iuk-stage

BASE    dc=informatik,dc=uni-rostock,dc=de
URI     ldaps://ldap2.informatik.uni-rostock.de

TLS_CACERT      /etc/ssl/certs/ca-certificates.crt

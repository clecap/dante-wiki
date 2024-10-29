



LoadModule auth_basic_module modules/mod_auth_basic.so
LoadModule authnz_ldap_module modules/mod_authnz_ldap.so
LoadModule ldap_module modules/mod_ldap.so

LDAPTrustedMode SSL


##### CAVE: LOCATION
##### CAVE  format crt or pem 

LDAPTrustedGlobalCert CA_BASE64 /etc/ssl/apache2/telekom_rootcert_base64.pem

<Directory />
  Allow from all
  AuthName "Account Rechenzentrum"
  AuthBasicProvider ldap
  AuthLDAPURL ldaps://ldap.uni-rostock.de/ou=people,o=uni-rostock,c=de?uid?sub?(objectclass=*)
  AuthLDAPBindDN "uid=xxx,ou=xxx,o=uni-rostock,c=de"
  AuthLDAPBindPassword "xxx"
  AuthType Basic
  Order allow,deny
  Require valid-user 
</Directory>






curl -o /etc/ssl/apache2/telekom_rootcert_base64.pem https://corporate-pki.telekom.de/crt/GlobalRoot_Class_2.crt
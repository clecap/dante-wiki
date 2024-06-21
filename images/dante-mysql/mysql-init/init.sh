#!/bin/sh
set -e

# Use environment variables to construct SQL commands

echo " "
echo "*** dante/mysqlinit.sh running now"



echo "*** /lap-entrypoint.sh sees the following secrets file:"
ls -alg /run/secrets
echo ""
if [ -f "/run/secrets/configuration" ]; then
    echo "*** /lap-entrypoint.sh will now load configuration"
    source /run/secrets/configuration
    echo "*** /lap-entrypoint.sh did load configuration"
  else
    echo "*** /lap-entrypoint.sh could not find configuration file, EXITING "
    exit 1
fi

# do this to prevent warning about passwords being used on the command line
export MYSQL_PWD=${MYSQL_ROOT_PASSWORD}

mysql -u root <<-EOF
  CREATE DATABASE IF NOT EXISTS ${MY_DB_NAME} /*\!40100 DEFAULT CHARACTER SET utf8 */;
  CREATE USER IF NOT EXISTS ${MY_DB_USER}@'172.16.0.0/255.240.0.0' IDENTIFIED BY '${MY_DB_PASS}';
  CREATE USER IF NOT EXISTS ${MY_DB_USER}@'192.168.0.0/255.255.0.0' IDENTIFIED BY '${MY_DB_PASS}';
  GRANT ALL PRIVILEGES ON ${MY_DB_NAME}.* TO '${MY_DB_USER}'@'172.16.0.0/255.240.0.0';
  GRANT ALL PRIVILEGES ON ${MY_DB_NAME}.* TO '${MY_DB_USER}'@'192.168.0.0/255.255.0.0';
  FLUSH PRIVILEGES;
EOF

mysql -u root <<-EOF
  SHOW DATABASES;
EOF

echo " "
echo "*** USERS: "

mysql -u root <<-EOF
  SELECT User, Host, authentication_string FROM mysql.user;
EOF


#mysql -u root <<-EOF
#  UPDATE mysql.user SET Host='192.168.0.0/255.255.0.0' WHERE User='root';
#  FLUSH PRIVILEGES;
#EOF


#mysql -u root <<-EOF
#  UPDATE mysql.user SET Host='192.168.0.0/255.255.0.0' WHERE User='root';
#  FLUSH PRIVILEGES;
#EOF


echo " "
echo "*** USERS: "

mysql -u root <<-EOF
  SELECT User, Host FROM mysql.user;
EOF



#mysql -u root <<-EOF
#  DELETE FROM mysql.user WHERE User='';
#  DROP DATABASE IF EXISTS test;
#  DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
#  UPDATE mysql.user SET Host='localhost' WHERE User='root';
#  FLUSH PRIVILEGES;
#  SHOW USERS;
#EOF

# Name of a temporary file for building up the mail
TMPFILE=`mktemp`

# generate header in mail file
echo "To: $SMTP_TO"         >> $TMPFILE
echo "From: $SMTP_FROM"       >> $TMPFILE
echo "Subject: Mysql initialized " >> $TMPFILE

msmtp --host=${SMTP_HOST} --port=${SMTP_PORT} --auth=on --user=${SMTP_USER} --passwordeval="echo $SMTP_PASSWORD" --tls=on --from=${SMTP_FROM}  ${SMTP_TO} < $TMPFILE

echo " "
echo "*** Completed dante/mysql-init/init.sh"
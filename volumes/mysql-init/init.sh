#!/bin/bash
#
# CAVE: This must be /bin/bash since we need the source built-in

set -e


exec 1>&1 2>&2
exec 1>&1 2>&2

echo ""
echo "**********************************************"
echo "*** volumes/mysql-init/init.sh running now ***"
echo "**********************************************"
echo ""

printf "*** List of /run/secrets\n\n"
  ls -alg /run/secrets
printf "\nDONE"
exec 1>&1 2>&2

if [ -f "/run/secrets/configuration" ]; then
    printf "\n*** dante/mysqlinit.sh  will now load configuration\n"
    source /run/secrets/configuration
    printf "\nDONE loading configuration"
    exec 1>&1 2>&2
  else
    printf "\n*** dante/mysqlinit.sh  could not find configuration file, EXITING\n\n"
    exit 1
fi

# do this to prevent warning about passwords being used on the command line
export MYSQL_PWD=${MARIADB_ROOT_PASSWORD}

sleep 5

printf "*** List of USERS:\n"
mysql -u root   <<-EOF
  SELECT User, Host, authentication_string FROM mysql.user;
EOF
printf "\n*** DONE USERS\n\n"
exec 1>&1 2>&2

printf "*** List of DATABASES: \n\n"
mysql -u root <<-EOF
  SHOW DATABASES;
EOF
printf "*** DONE DATABASES\n\n"
exec 1>&1 2>&2

printf "*** Setting new root password: \n"
mysql -u root -p${MYSQL_PWD} <<-EOF
  ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
  ALTER USER 'root'@'%' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
  flush privileges;
EOF
printf "DONE root password"

export MYSQL_PWD="${MYSQL_ROOT_PASSWORD}"

printf "*** List of USERS:\n"
mysql -u root   <<-EOF
  SELECT User, Host, authentication_string FROM mysql.user;
EOF
printf "\n*** DONE USERS\n\n"
exec 1>&1 2>&2


printf "\n\n*** Creating required databases and users:\n"
mysql -u root <<-EOF
  CREATE DATABASE IF NOT EXISTS ${MY_DB_NAME} /*\!40100 DEFAULT CHARACTER SET utf8 */;
  CREATE USER IF NOT EXISTS ${MY_DB_USER}@'172.16.0.0/255.240.0.0' IDENTIFIED BY '${MY_DB_PASS}';
  CREATE USER IF NOT EXISTS ${MY_DB_USER}@'192.168.0.0/255.255.0.0' IDENTIFIED BY '${MY_DB_PASS}';
  GRANT ALL PRIVILEGES ON ${MY_DB_NAME}.* TO '${MY_DB_USER}'@'172.16.0.0/255.240.0.0';
  GRANT ALL PRIVILEGES ON ${MY_DB_NAME}.* TO '${MY_DB_USER}'@'192.168.0.0/255.255.0.0';
  FLUSH PRIVILEGES;
EOF
printf "*** DONE creating databases\n\n"
exec 1>&1 2>&2

printf "*** List of USERS:\n\n"
mysql -u root <<-EOF
  SELECT User, Host, authentication_string FROM mysql.user;
EOF
printf "\n*** DONE USERS\n\n"
exec 1>&1 2>&2


printf "*** List of DATABASES: \n\n"
mysql -u root <<-EOF
  SHOW DATABASES;
EOF
printf "\n*** DONE DATABASES\n"
exec 1>&1 2>&2



# sleep infinity
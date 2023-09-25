#!/bin/bash

# adds a user of name USER and a database of name DB_USER with password to the database
#
# picks up the mysql root password from a ../../conf file customize-PRIVATE.sh


# todo: also add a abckup user for this particular data base

usage() {
  echo "Usage: $0 USER(no - only _)   PASSWORD" >&2
  exit 1
}

password() {
  read -s -p "Enter password: " PASS
  echo ""
  read -s -p "Enter password again: " PASS_AGAIN
  if [ "$PASS" == "$PASS_AGAIN"  ]; then
    echo ""
  else
    echo ""
    echo ""
    echo "Passwords different - ABORTING!"
    echo ""
    exit 1
  fi
}

echo ""
if [ "$#" -eq 0 ]; then
  read -p "Enter username USER. Database will be DB_USER: " USER
  password
fi
if [ "$#" -eq 1 ]; then
  USER=$1
   password
fi
if [ "$#" -eq 2 ]; then
  USER=$1
  PASS=$2
fi
if [ "$#" -gt 2 ]; then
  usage
fi

source ../../conf/customize-PRIVATE.sh

DB=DB_${USER}

CONTAINER_NAME=my-mysql

echo "User: ${USER} for Database: ${DB} with Password: ${PASS}"


#### TODO: CAVE: too many rights 

##### TODO: need error messages when user already exists - and an abort as well 

docker exec -i ${CONTAINER_NAME} mysql -u root --password=${MYSQL_ROOT_PASSWORD} <<MYSQL_SCRIPT
CREATE DATABASE ${DB} /*\!40100 DEFAULT CHARACTER SET utf8 */;
CREATE USER ${USER}@'%' IDENTIFIED BY '${PASS}';
CREATE USER ${USER}@localhost IDENTIFIED BY '${PASS}';
CREATE USER ${USER}@'0.0.0.0/0.0.0.0' IDENTIFIED BY '${PASS}';
GRANT ALL PRIVILEGES ON ${DB}.* TO '${USER}'@'%';
GRANT ALL PRIVILEGES ON ${DB}.* TO '${USER}'@'localhost';
GRANT ALL PRIVILEGES ON ${DB}.* TO '${USER}'@'0.0.0.0/0.0.0.0';
GRANT ALL ON *.* TO '${USER}'@'%';
GRANT ALL ON *.* TO '${USER}'@'localhost';
GRANT ALL ON *.* TO '${USER}'@'0.0.0.0/0.0.0.0';
FLUSH PRIVILEGES;
MYSQL_SCRIPT


echo ""
echo "DONE"



#    echo "Please enter root user MySQL password!"
#    echo "Note: password will be hidden when typing"
#    read -sp rootpasswd
#    mysql -uroot -p${rootpasswd} -e "CREATE DATABASE ${MAINDB} /*\!40100 DEFAULT CHARACTER SET utf8 */;"
#    mysql -uroot -p${rootpasswd} -e "CREATE USER ${MAINDB}@localhost IDENTIFIED BY '${PASSWDDB}';"
#    mysql -uroot -p${rootpasswd} -e "GRANT ALL PRIVILEGES ON ${MAINDB}.* TO '${MAINDB}'@'localhost';"
#    mysql -uroot -p${rootpasswd} -e "FLUSH PRIVILEGES;"
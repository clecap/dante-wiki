#!/bin/sh



# call the specific entrypoint of ssh docker
source ssh-entry.sh


echo ""
echo "*** This is my-mysql:entrypoint.sh ***" 
echo ""
echo "** Directory listing of /var:"
ls -alg /var
echo ""
echo "** Directory listing of /var/mysql:"
ls -alg /var/mysql
echo ""




####################################################  CAVE: we are not setting a mysql root password !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!


mkdir -p /run/mysqld
chown -R mysql:mysql /run/mysqld

# CAVE: we want logs at /var/mysql/log because there they are part of the data base volume and not of the my-mysql container
mkdir -p /var/mysql/log 
chown -R mysql:mysql /var/mysql/log 

chown -R mysql:mysql /var/mysql/
chown -R mysql:mysql /var/mysql/mysql

## Data volume is /var/mysql
## If the next level directory /var/mysql/mysql exists then the volume has been initialized already
##
if [ -d /var/mysql/mysql ]; then
  echo "*** MySQL directory /var/mysql/mysql already present, skipping creation"
  chown -R mysql:mysql /var/mysql/mysql
else
  echo "*** MySQL data directory /var/mysql/mysql not found, creating it"
  mkdir -p /var/mysql/mysql
  chown -R mysql:mysql /var/mysql/mysql
  echo ""
  echo "** Directory listing of /var/mysql: "
  ls -alg /var/mysql/
  echo ""

  echo "*** Running mysql_install_db for the FIRST time"
	mysql_install_db --user=mysql --datadir=/var/mysql/mysql --verbose
  echo "*** DONE"
  echo ""

  # get a temporary file
  tfile=`mktemp`
  if [ ! -f "$tfile" ]; then
    return 1
  fi


  cat << EOF > $tfile
USE mysql;
FLUSH PRIVILEGES;
GRANT ALL ON *.* TO 'root'@'%' identified by '$MYSQL_ROOT_PASSWORD' WITH GRANT OPTION ;
SET PASSWORD FOR 'root'@'localhost'=PASSWORD('${MYSQL_ROOT_PASSWORD}') ;
FLUSH PRIVILEGES ;
CREATE USER '${MYSQL_DUMP_USER}'@'localhost' IDENTIFIED BY '${MYSQL_DUMP_PASSWORD}';
GRANT SELECT, SHOW VIEW, LOCK TABLES, RELOAD, REPLICATION CLIENT ON DATABASE_NAME.* TO '${MYSQL_DUMP_USER}'@'localhost' IDENTIFIED BY '${MYSQL_DUMP_PASSWORD}';
CREATE USER '${MYSQL_DUMP_USER}'@'%' IDENTIFIED BY '${MYQSL_DUMP_PASSWORD}';
GRANT SELECT, SHOW VIEW, LOCK TABLES, RELOAD, REPLICATION CLIENT ON DATABASE_NAME.* TO '${MYSQL_DUMP_USER}'@'%' IDENTIFIED BY '${MYSQL_DUMP_PASSWORD}';
FLUSH PRIVILEGES ;
EOF



#     GRANT ALL ON *.* TO 'root'@'localhost' identified by '$MYSQL_ROOT_PASSWORD' WITH GRANT OPTION ;

    echo "*** Will now set root password ${MYSQL_ROOT_PASSWORD}"

#   we MUST provide some passwords otherwise we cannot 
  /usr/bin/mysqld --user=mysql --bootstrap --skip-name-resolve --verbose=0  --skip-networking=0 < $tfile
  rm -f $tfile
  echo "* Done making root password"
  echo " "

  echo
  echo 'MySQL init process complete - STARTING UP NOW'
  echo

  echo "exec /usr/bin/mysqld --user=mysql --console --skip-name-resolve --skip-networking=0" "$@"
fi

echo " "
echo "*** NORMAL START of DATABASE OPERATIONS ***"
echo " "

exec /usr/bin/mysqld --user=mysql --console --skip-name-resolve --skip-networking=0 $@
echo ""
echo "" PASSWORD PROBLEM
echo "YOU DID NOT CONFIGURE THIS CORRECTLY - CHECKFILE customize files in /conf"
echo ""

MYSQL_ROOT_PASSWORD=password

# User entitled to do a dump of the entire mysql installation
MYSQL_DUMP_USER=username
MYSQL_DUMP_PASSWORD=otherpassword

DEFAULT_DB_VOLUME_NAME=my-mysql-data-volume

MW_SITE_SERVER=https://localhost:4443

MW_SITE_NAME="Localhost Wiki for Hot Development"


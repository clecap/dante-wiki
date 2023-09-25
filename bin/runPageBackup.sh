#!/bin/zsh 


if [ $# -eq 0 ]; then
    echo "No arguments provided"
    exit 1
fi


set -o noclobber
docker exec -it my-dante php /var/www/html/maintenance/dumpBackup.php --full 


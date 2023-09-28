


# get directory where this script resides wherever it is called from
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
TOP_DIR=${DIR}/../../../

# directory where we look for keys
KEY_DIR=${TOP_DIR}/../KEYS-AND-CERTIFICATES

usage() {
  echo "injects keys from directory ${KEY_DIR} into a lap container of dantewiki "
  echo "  "
  echo "  $0  iuk-dante                "
  echo "  $0  pro         macPro localhost    "
  echo "  $0  power       powerbook localhost "
  echo "  $0  NAME        where NAME is an arbitrary string [a-zA-Z0-9]* see README"
  exit 1
}

if [ "$#" -eq 0 ]; then    # No parameter given, do a usage
  echo "No parameter"
  usage
  exit 
fi

PRIVATE_KEY="$KEY_DIR/$1.key"
PUBLIC_KEY="$KEY_DIR/$1.pem"

# name of the container into which we should copy this in
LAP_CONTAINER=my-lap-container

printf "*** Setting up public key infrastructure, if present\n\n"
  if [ -f $PRIVATE_KEY ]; then
    chmod 400 ${PRIVATE_KEY}
    printf "*** Found a private key at ${PRIVATE_KEY}, copying it in and fixing permissions ... \n" 
    docker cp $PRIVATE_KEY    $LAP_CONTAINER:/etc/ssl/apache2/server.key
    docker exec -it $LAP_CONTAINER   chown root.root /etc/ssl/apache2/server.key
    docker exec -it $LAP_CONTAINER   chmod 400 /etc/ssl/apache2/server.key
    printf "DONE\n\n"
  else
    printf "%b" "\e[1;31m *** ERROR: Found no private key, checked at ${PRIVATE_KEY} *** *** \e[0m"
    exit 1
  fi
  if [ -f $PUBLIC_KEY ]; then
    printf "*** Found a public key at ${PUBLIC_KEY}, copying it in and fixing permissions ... \n" 
    chmod 444 ${PUBLIC_KEY}
    docker cp $PUBLIC_KEY $LAP_CONTAINER:/etc/ssl/apache2/server.pem
    docker exec -it $LAP_CONTAINER   chown root.root /etc/ssl/apache2/server.pem
    docker exec -it $LAP_CONTAINER   chmod 444 /etc/ssl/apache2/server.pem
    printf "DONE\n\n"
  else
    printf "%b" "\e[1;31m *** ERROR: Found no private key, checked at ${PRIVATE_KEY} *** *** \e[0m"
    exit 1
  fi

printf "*** Killing apaches and waiting 10 seconds for processes to settle\n"
  docker exec -it $LAP_CONTAINER  killall httpd
  sleep 10
printf "DONE\n\n"

printf "*** Restarting apaches\n"
  docker exec -it $LAP_CONTAINER  httpd
printf "DONE\n\n"


printf "%b" "\e[1;32m *** DONE injecting key *** \e[0m"

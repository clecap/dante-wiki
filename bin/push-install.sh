#!/bin/bash



IMAGE="docker.io/clecap/dante-wiki:latest"

COMPOSE_FILE="compose/docker-compose-development.yaml"



## Pushes an installation to a machine where the user has shell access

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"                                # directory where this script resides wherever it is called from
TOP_DIR=${DIR}/..                                                                      # top directory of the entire repository
source $DIR/library.sh || { printf "\e[1;31mERROR: could not read $DIR/library.sh\e[0m\n"; exit 1; }   # library.sh not loaded: no color variables yet

# NOTE: printf %b turns the color codes from library.sh into real colors; read -p would print them literally
read -p "$(printf "%b" "${ERROR}Name of the remote machine: ${RESET}")" REMOTE_MACHINE
[ -n "$REMOTE_MACHINE" ] || { printf "%b\n" "${ERROR}ERROR: no remote machine given${RESET}"; exit 1; }

read -p "$(printf "%b" "${ERROR}User name on $REMOTE_MACHINE [$USER]: ${RESET}")" REMOTE_USER   # empty input: use the local user name
REMOTE_USER=${REMOTE_USER:-$USER}

read -p "$(printf "%b" "${ERROR}Target directory on $REMOTE_MACHINE: ${RESET}")" TARGET_DIR
[ -n "$TARGET_DIR" ] || { printf "%b\n" "${ERROR}ERROR: no target directory given${RESET}"; exit 1; }

read -p "$(printf "%b" "${ERROR}Configuration tag: ${RESET}")" CONFIG_TAG
CONFIG_FILE="${TOP_DIR}/private/${CONFIG_TAG}/configuration-${CONFIG_TAG}.sh"
[ -n "$CONFIG_TAG" ] && [ -f "$CONFIG_FILE" ] || { printf "%b\n" "${ERROR}ERROR: configuration file not found: $CONFIG_FILE${RESET}"; exit 1; }


# All ssh/scp calls share one connection, so the password is asked only once.
# User:                 user name on the remote machine (-o User works for both ssh and scp; scp -l means something else)
# ControlMaster=auto:   the first call opens the connection, later calls reuse it
# ControlPath:          socket file of the shared connection; %C is a hash of user, host and port (keeps the path short)
# ControlPersist=60:    keep the connection open for 60 seconds after the last call
SSH_OPTS=(-o User="$REMOTE_USER" -o ControlMaster=auto -o ControlPath="$HOME/.ssh/cm-%C" -o ControlPersist=60)

trap 'ssh "${SSH_OPTS[@]}" -O exit "$REMOTE_MACHINE" 2>/dev/null' EXIT                # close the shared connection when the script ends

REMOTE="$REMOTE_USER@$REMOTE_MACHINE"                                                  # only for messages

# Open the shared connection: ask for the password once and run no command.
# -N: no remote command   -f: go to the background after login
# The connection stays open until the trap above closes it at the end of the script; all later ssh/scp calls reuse it.
start "Opening connection to $REMOTE"
  ssh "${SSH_OPTS[@]}" -f -N "$REMOTE_MACHINE" || { printf "%b\n" "${ERROR}ERROR: could not connect to $REMOTE${RESET}"; exit 1; }
ok "Connected"

start "Creating directories $TARGET_DIR/private, $TARGET_DIR/bin and $TARGET_DIR/compose on $REMOTE"
  ssh "${SSH_OPTS[@]}" "$REMOTE_MACHINE" "mkdir -p '$TARGET_DIR/private' '$TARGET_DIR/bin' '$TARGET_DIR/compose'" || { printf "%b\n" "${ERROR}ERROR: could not create directories in $TARGET_DIR on $REMOTE${RESET}"; exit 1; }
ok "Created directories"

start "Copying private/$CONFIG_TAG/configuration-$CONFIG_TAG.sh to $REMOTE:$TARGET_DIR/private/"
  scp "${SSH_OPTS[@]}" "$CONFIG_FILE" "$REMOTE_MACHINE:$TARGET_DIR/private/" || { printf "%b\n" "${ERROR}ERROR: could not copy $CONFIG_FILE to $REMOTE${RESET}"; exit 1; }
ok "Copied"

start "Linking $TARGET_DIR/private/configuration.sh to configuration-$CONFIG_TAG.sh on $REMOTE"
  ssh "${SSH_OPTS[@]}" "$REMOTE_MACHINE" "ln -sf 'configuration-$CONFIG_TAG.sh' '$TARGET_DIR/private/configuration.sh'" || { printf "%b\n" "${ERROR}ERROR: could not link configuration on $REMOTE${RESET}"; exit 1; }
ok "Linked"

start "Copying bin/library.sh and bin/install.sh to $REMOTE:$TARGET_DIR/bin/"
  scp "${SSH_OPTS[@]}" "$DIR/library.sh" "$DIR/install.sh" "$REMOTE_MACHINE:$TARGET_DIR/bin/" || { printf "%b\n" "${ERROR}ERROR: could not copy bin files to $REMOTE${RESET}"; exit 1; }
ok "Copyied"

start "Copying $COMPOSE_FILE to $REMOTE:$TARGET_DIR/compose/"
  scp "${SSH_OPTS[@]}" "$TOP_DIR/$COMPOSE_FILE" "$REMOTE_MACHINE:$TARGET_DIR/compose/" || { printf "%b\n" "${ERROR}ERROR: could not copy $COMPOSE_FILE to $REMOTE${RESET}"; exit 1; }
ok "Copied"

start "Pulling image $IMAGE on $REMOTE"
  ssh "${SSH_OPTS[@]}" "$REMOTE_MACHINE" "docker pull '$IMAGE'" || { printf "%b\n" "${ERROR}ERROR: could not pull $IMAGE on $REMOTE${RESET}"; exit 1; }
ok "Pulled"

# the compose file uses the image name dante-wiki:latest (the name of a locally built image)
start "Tagging $IMAGE as dante-wiki:latest on $REMOTE"
  ssh "${SSH_OPTS[@]}" "$REMOTE_MACHINE" "docker tag '$IMAGE' dante-wiki:latest" || { printf "%b\n" "${ERROR}ERROR: could not tag $IMAGE on $REMOTE${RESET}"; exit 1; }
ok "Tagged"


# testing
exit 1


# The compose file needs variables from the configuration (MY_DOMAINNAME, HOST_HTTPS_PORT), so the remote bash
# reads the configuration first. The commands are sent through stdin; the unquoted EOF fills in local variables.
DOCKER_SERVICES="database webserver-raw-https phpmyadmin"
printf "Starting services $DOCKER_SERVICES with $COMPOSE_FILE on $REMOTE\n"
ssh "${SSH_OPTS[@]}" "$REMOTE_MACHINE" bash -s <<EOF || { printf "%b\n" "${ERROR}ERROR: could not start services on $REMOTE${RESET}"; exit 1; }
set -e
cd '$TARGET_DIR'
source private/configuration.sh > /dev/null
docker compose -f '$COMPOSE_FILE' up -d $DOCKER_SERVICES
EOF

printf "Done: files copied to $REMOTE:$TARGET_DIR, image $IMAGE pulled, services $DOCKER_SERVICES started\n"






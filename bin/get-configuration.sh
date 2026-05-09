#!/bin/bash


CONFIG="iuk-stage"
FILENAME="configuration-$CONFIG.sh"
CONFIG_ENCRYPTED_URL="https://iuk.one/configuration-$CONFIG.sh.enc"

printf "\n"
read -s -p "Enter decryption password: " CONFIG_DECRYPTION_KEY
echo
export CONFIG_DECRYPTION_KEY

MNT="${PWD}/private/decr"
mkdir -p "$MNT"
chmod 777 "$MNT"

# Use an image which has openssl and wget
IMAGE="alpine/openssl"

docker run --rm                                       \
  -e CONFIG_ENCRYPTED_URL="$CONFIG_ENCRYPTED_URL"     \
  -e CONFIG_DECRYPTION_KEY="$CONFIG_DECRYPTION_KEY"   \
  -e FILENAME="$FILENAME"                             \
  -v "$MNT:/out" \
  --entrypoint sh "$IMAGE" -c '
    wget -O "/tmp/$FILENAME.enc" "$CONFIG_ENCRYPTED_URL"
    openssl enc -d -aes-256-cbc -pbkdf2 \
      -pass env:CONFIG_DECRYPTION_KEY   \
      -in "/tmp/$FILENAME.enc"          \
      -out "/out/$FILENAME"
    chmod 0400 "/out/$FILENAME"
  '

# docker compose up -d








#!/bin/bash

# Install initial contents elements from github
# 
#
#


source /home/dante/dantescript/common-defs.sh

## loadSecrets

OWNER="clecap"
REPO="dante-wiki-contents"
BRANCH="master"  
TOKEN=""

# URL-encode a string (handles special characters in owner/token)
urlencode() {
  printf '%s' "$1" | python3 -c "import sys, urllib.parse; print(urllib.parse.quote(sys.stdin.read(), safe=''), end='')"
}

REPO_URL="https://${OWNER}:${TOKEN}@github.com/${OWNER}/${REPO}.git"

TARGET_DIR=$(mktemp -d)

git clone --depth=1 --single-branch --branch "$BRANCH" "$REPO_URL" "$TARGET_DIR"
php $IP/extensions/DanteCommon/importDirectory.php --ddir "$TARGET_DIR" --slug

trap 'errorTrap' ERR

trap - ERR




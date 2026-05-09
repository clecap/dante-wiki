#!/bin/bash

encryptFile()
{
  if [ -z "$1" ]; then
    echo "Usage: encryptFile <filename>"
    return 1
  fi
  if [ ! -f "$1" ]; then
    echo "Error: file '$1' not found."
    return 1
  fi

  read -s -p "Enter encryption password: " password
  echo
  read -s -p "Confirm password: " password2
  echo
  if [ "$password" != "$password2" ]; then
    echo "Error: passwords do not match."
    return 1
  fi

  openssl enc -aes-256-cbc -salt -pbkdf2 -in "$1" -out "$1.enc" -pass stdin <<< "$password"
  echo "Encrypted file written to $1.enc"
}

encryptFile "private/configuration-$1.sh"

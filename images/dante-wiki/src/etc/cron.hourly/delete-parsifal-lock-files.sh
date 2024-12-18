#!/bin/bash

DIRE="/var/lock/parsifal"

# Find and delete files older than 1 hour
find "$DIRE" -type f -mmin +60 -exec rm -f {} \;

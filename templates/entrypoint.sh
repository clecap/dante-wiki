#!/bin/sh
# ssh-keygen -A

exec /usr/sbin/sshd -D -e "$@"

#/usr/sbin/sshd -D -e



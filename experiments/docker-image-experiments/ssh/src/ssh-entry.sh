#!/bin/sh

# Script which may be called by entrypoint.sh
# Only called if we do not overwrite entrypoint.sh by subsequent layers
#

makessh () 
{
  echo " Found username ${USERNAME}"

  echo "** Generating our own, local ssh key, unique for the specific container itself..."
  ssh-keygen -A
  echo "DONE generating our own, local ssh key, unique for the specific container itself"

  echo ""; echo "The public key of this container is:"; echo "________________"; echo"";
  cat /etc/ssh/ssh_host_rsa_key.pub
  echo "";

  echo ""; echo "** Adding user ${USERNAME} to the container..."
  adduser -h /home/${USERNAME} -s /bin/sh -D ${USERNAME}
  # now we MUST add a password (or else the account is considered locked and permits no ssh access)
  # we want to add a random password not known to anyone to disable any use of that account except a public key ssh logon
  # we already turned off password authentication for sshd in the docker file
  # to be on the safe side we supply a random password freshly generated and known to nobody
  # echo -n 'cap:pass' | chpasswd 
  echo "${USERNAME}:"`tr -dc A-Za-z0-9 </dev/urandom | head -c 16` | chpasswd
  echo "DONE adding user ${USERNAME}"

  echo ""; echo "** Allowing user ${USERNAME} to do a passwordless sudo..."
  echo "${USERNAME} ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/${USERNAME}
  chmod 0440 /etc/sudoers.d/${USERNAME}
  echo "DONE allowing passwordless sudo to ${USERNAME}"

  echo ""; echo "** Establishing login-key.pub as public key for ${USERNAME}..."
  mkdir /home/${USERNAME}/.ssh
  chown ${USERNAME} /home/${USERNAME}/.ssh
  chmod 0700 /home/${USERNAME}/.ssh
  cp login-key.pub /home/${USERNAME}/.ssh/authorized_keys
# the ownership and the permission MUST be correct for ssh to work

  chmod 0400 /home/${USERNAME}/.ssh/authorized_keys
  chown ${USERNAME} /home/${USERNAME}/.ssh/authorized_keys
  echo "DONE establishing login-key.pub as public key for ${USERNAME}"

  echo ""; echo "** Starting ssh daemon..."
  /usr/sbin/sshd 
  echo "DONE starting ssh daemon"

#  echo ""; echo "** Starting ssh daemon in foreground..."
#  exec /usr/sbin/sshd -D -e "$@"
#
#  /usr/sbin/sshd -d -D
#  Add -d for debug mode

# exec /usr/sbin/sshd -D -e "$@"
# -e
#  echo "INFO: after starting sshd (should not happen)"

#### control now handed back to calling entrypoint.sh

}

nossh () 
{
  echo ""; echo "** No environment variable USERNAME found: Not generating any ssh opportunity"; echo ""
}



echo ""; echo "Hello, I am $0"; echo ""

if [[ -z "$USERNAME" ]] ; then
  nossh
else
  makessh
fi

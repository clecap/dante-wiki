# Preparing Docker

## Quick Install on a VM

1. Log on to a VM running Debian under a user name capable of `sudo`.
2. Copy-and-paste this into a shell running on the VM.
  ```curl -fsSL https://raw.githubusercontent.com/clecap/dante-wiki-production/HEAD/bin/prepare-docker.sh | sudo /bin/bash```

**Note:** Running an unknown shell script as root can be dangerous unless you completely trust that script. 
Only do this on an ephemeral virtual machine.
On a different machine, check the script or do a setp-by-step manual install, as below.

## Manual Install

#### Install missing unzip 
* ```apt-get install unzip```

#### Fix a locale problem inherent in most Debian installations
*   `sudo su locale-gen en_US.UTF-8`
* `sudo su -`
* Edit `/etc/default/locale` to have the following contents:
  ```
  LC_CTYPE="en_US.UTF-8"
  LC_ALL="en_US.UTF-8"
  LANG="en_US.UTF-8" 
  ```
* Log out and log in again.

#### Generate properly qualified user
* We need a user with 
  * a home directory (in which we install everything)
  * with shell /bin/bash, 
  * with docker rights (i.e. belonging to group docker).

  ```
  sudo adduser --disabled-password dante
  sudo chsh -s /bin/bash dante
  grep 'dante' /etc/passwd
  sudo grep 'dante' /etc/shadow
  sudo usermod -aG docker dante
   ```

#### Install docker

* Install docker
  ```
  sudo apt update
  sudo apt install apt-transport-https ca-certificates curl gnupg2 software-properties-common
  sudo curl -fsSL https://get.docker.com -o get-docker.sh
  sudo sh ./get-docker.sh
  ```


## Some helpful commands and references

* Find out, which shell we are running in: 
 `echo $0`

* https://docs.docker.com/engine/install/linux-postinstall/#manage-docker-as-a-non-root-user

## Starting docker on a Debian VM
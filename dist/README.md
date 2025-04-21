

## Installation 

  ssh to MACHINE

*  `sudo su -`
*  `su - dante`
*  `cd`
*  `/bin/bash`
* `/bin/bash -c "$(curl -fsSL https://github.com/clecap/dante-wiki/raw/refs/heads/master/dist/get.sh)"`
* `dist/run.sh`


### Security Assumption: Private Installation

* We install on a private hosting machine to which no other suers have access.
* ISSUE: configuration.sh must be readable by the docker process but not readable by other users on the machine



### Hard Cleaning ##

Clean absolute everything on docker:

  docker system prune -a --volumes -f




## Base Image

The base image is debian slim.

Alpine works, but (especially in the higher versions) poses numerous difficulties for
packages which have not been properly adapted (yet). Also, Alpine repository does not
keep older versions, since the team claims they do not have the resources for doing so.

Update: Using Alpine instead of Debian proves to have been the one big mistake and time-waster
in my initial work. Debian is so much more straight-forward and Alpine makes so many things different.
With a large image size of some 5 GB the different between an Alpine and Debian base (of some 150 MB) 
is very small. Alpine only is reasonable if what you add to the base really is very small.


## Apt-Get
* Using multiple lines of apt-get seems to work better than all in a single apt-get. Could not pinpoint the
reason, but observed it that way frequently.

## Paths in Shells

#### Find top level directory inside of a git repository:
TOP_DIR=$(git rev-parse --show-toplevel 2>/dev/null || echo "$PWD")

#### get directory this shell is running in
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"


## Arrow keys Issue in Shell

The reason is that docker and debian usually has /bin/sh linked to /bin/dash instead of /bin/bash.
Solution is to make a fresh link.



## Docker logs

Sometimes the docker logs do not produce the logs of events in the right sequence. This may be due to
1. stderr and stdout being interleaved
2. stdout being line-buffered and printf only producing a full line at \n

As a relief we can try to flush stdout and stderr explicitely using:
  exec 1>&1 2>&2


## Vscodium Automatic installation of an extension
``` 
NAME=file-action-0.0.31.vsix
rm -f /tmp/${NAME}
wget https://raw.githubusercontent.com/clecap/file-action/main/${NAME}  -O /tmp/${NAME}
codium --install-extension /tmp/${NAME}
rm -f /tmp/${NAME}
```  

## VSCODIUM

* Need extension "Ansi Colors" to see colours in output window.

## set -e

set -e leads to an immediate abort of the script in case of an error. Also a trap is not
taken (unless, maybe, it is on EXIT). Thus, control does not return to the calling script
for error handling.
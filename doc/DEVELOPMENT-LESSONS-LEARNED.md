

## Base Image

The base image is debian slim.

Alpine works, but (especially in the higher versions) poses numerous difficulties for
packages which have not been properly adapted (yet). Also, Alpine repository does not
keep older versions, since the team claims they do not have the resources for doing so.


## Apt-Get
* Using multiple lines of apt-get seems to work better than all in a single apt-get. Could not pinpoint the
reason, but observed it that way frequently.

## Paths in Shells

#### Find top level directory inside of a git repository:
TOP_DIR=$(git rev-parse --show-toplevel 2>/dev/null || echo "$PWD")

#### get directory this shell is running in
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"


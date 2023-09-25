This directory is used to construct a TexLive docker image including many additional tools for using LaTeX,


### generate.sh ###

Build a docker image which is derived from ssh and now gets added a Texlive installation.

### gettex.sh ###

Shell script for getting a copy of the CTAN TeX archive.

However, we cannot use it here, since the docker has no file system level access to the repository on the host in our current setting.


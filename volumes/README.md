# Volumes #

## Idea ##
Every subdirectory of directory `volumes` represents a volume description.

A volume description can be used
* to generate a **directory** which can be bound as directory to a local docker container
* to generate a **docker volume** on the local host 
* to generate an **AWS EFS elastic file system** to be used, for example, in an AWS Fargate container.


## Conventions ##

* `./content` is the content of the volume. It can be reconstructed by the shell scripts in `spec` and thus can be deleted at any time.
* `./spec`contains shell scripts for building up the contents in content
* `./README.md`is a short description of the volume description.

## Our Volumes ##

Currently we have to following volume descriptions:

* `full``
* `minimal``





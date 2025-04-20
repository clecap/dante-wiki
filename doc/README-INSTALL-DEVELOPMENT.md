
This is the README file for generating a development environment.


## Concepts

## Requirements on Target Machine

### 1. Install Docker on Target Machine
* Follow the instructions at https://docs.docker.com/engine/install/debian/
* Add your user to the docker group: ```sudo usermod -aG docker ${USER}```
* Log out and log in again as ${USER}
* Check if docker is operative: ```docker run hello-world```


### 2. Install git and git credential manager on Target Machine
* For Linux/Debian see: https://github.com/git-ecosystem/git-credential-manager/blob/release/docs/install.md and follow Debian instructions
* Get a github permission token
* Configure helper according to https://docs.github.com/en/get-started/getting-started-with-git/caching-your-github-credentials-in-git


## Docker Tags Used

* `stable`: The latest version which is running in a stable fashion and is ready for production.
* `development`: The version we are currently developing and changing on.
* `latest`: Is always the most recent image we generated.

## Build Process Local


* composer/generate-and-run-development.sh



## Docker Image Build on Dockerhub




# OLD STUFF

## Build Docker Images 

### Build on DockerHub



## Configure
1. Prepare file ```conf/customize-PRIVATE.sh``` following ```customize-SAMPLE.sh```
2. Prepare file ```conf/mediawiki-PRIVATE.php``` following ```mediawiki-SAMPLE.php```


## Build Volume Template

```bin/build-volume-template.sh```

This comprises the following steps:
1. Clean the template directory: ```rm -Rf volumes/full/content```
2. Build a directory serving as template for the working volume for the lap container: ```volumes/full/spec/cmd.sh```
3. Pull Dante Patches from github: ```volumes/full/spec/git-pull-from-delta.sh```
4. Install Parsifal: ```volumes/full/spec/git-clone-dante-from-parsifal.sh```


## Run (for Production Work)

### Quick: 
0.  ```bin/cleanup-remote.sh```
1.  ```bin/run-remote.sh```


#### More detailed
1. Build volume template   ```bin/build-volume-template.sh```
2. Prepare docker volume:  ```volumes/bin/add-dir.sh full sample-volume /```
3. Run processes:   ```images/lap/bin/both.sh --db my-test-db-volume --vol sample-volume```
4. Initialize Wiki: ```volumes/full/spec/wiki-init.sh```



##### Debug:
* Look into container (on target machine): ```docker exec -it my-lap-container /bin/ash```


## Run on a Local Target (Developmentwork only!)

1. Ensure that the repository is pushed !!!!!!!!!


### Case 1: Run on volume identical to a host directory

1. Run both processes: ```images/lap/bin/both.sh --db my-test-db-volume --dir full```
2. Initialize Wiki: ```volumes/full/spec/wiki-init.sh```

##### Debug:
Test: wget --no-check-certificate

## Startup Content: From large dump on file system  (PRIVATE !!!!!)

1. Log on: `docker exec -it --user apache  my-lap-container /bin/ash`
2. Copy in content: `scp cap@heinrich:/tmp/dump.xml /tmp`
3. echo "Main Page" > /tmp/list.txt
4. `php /var/www/html/wiki-dir/maintenance/deleteBatch.php /tmp/list.txt` 
5. Load MediaWiki portions: `php /var/www/html/wiki-dir/maintenance/importDump.php --namespaces "8" --debug /tmp/dump.xml`
6. Load Template portions: `php /var/www/html/wiki-dir/maintenance/importDump.php  --namespaces "10" --debug /tmp/dump.xml`
7. Load the rest: `php /var/www/html/wiki-dir/maintenance/importDump.php --report --namespaces "10" --debug /tmp/dump.xml`

##### Note
* We must delete the Main Page before the import, as the Main Page otherwise will be populated by a default text and not overwritten as intended.
* We must import the MediaWiki and Template portions before the pages or else we get errors due to missing Parsifal templates or Templates.

## Debug

#### Look into docker container

On the machine:  ```docker exec -it CONTAINER_NAME /bin/ash```

From outside:  ssh -i login-key -p 2222 cap@localhost

login-key is to be found on /images/ssh of the machine on which the container was run (do not confuse machines !)




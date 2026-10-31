
README file for ***generating a development environment***


# Requirements

## Requirements for Development
* Visual Studio Code on the development machine.
* Extension ms-vscode-remote.remote-containers installed on visual studio code. 


## Workflow

1. **Start a working instance as docker container** on your development machine.

```
  git clone https://github.com/clecap/dante-wiki
  bin/build-run-raw.sh
``` 

2. **Attach Visual Studio Code** to this container.

```
Command Palette (Cmd-Shift-P)): Dev Containers: Attach to Running Container...
Attach to container dante-wiki (may take a minute or so!)
```



# On Remote Machines

## Requirements
* Docker ...
* Git ...
* Bash ...


## Installation

* Log on as dante
* 

git clone --depth 1 https://github.com/clecap/dante-wiki



# Certificate for Development

Proper development practice requires a certificate for localhost which has been generated for the specific machine on which you are developing.

```
brew install mkcert              # install mkcert on MacOS
mkcert -install                  # creates a CA for this Mac and trusts it in the System keychain (Chrome uses it)
cd ~/tmp
mkcert localhost 127.0.0.1 ::1   # writes localhost+2.pem and localhost+2-key.pem
```

This generates certificates and keys for  https://localhost, https://127.0.0.1 and https://[::1]

Replace the values in `private/configuration.sh`: 
* APACHE_SERVER_KEY gets the contents of localhost+2-key.pem, 
* APACHE_SERVER_CRT gets the contents of localhost+2.pem.

Restart Chrome completely (Cmd+Q) after running mkcert.


# Partially old stuff


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

### Case 1: Run on volume identical to a host directory

1. Run both processes: ```images/lap/bin/both.sh --db my-test-db-volume --dir full```
2. Initialize Wiki: ```volumes/full/spec/wiki-init.sh```


##### Note
* We must delete the Main Page before the import, as the Main Page otherwise will be populated by a default text and not overwritten as intended.
* We must import the MediaWiki and Template portions before the pages or else we get errors due to missing Parsifal templates or Templates.






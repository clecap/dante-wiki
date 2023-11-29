#!/bin/bash


WIKI_VERSION_MAJOR=1.39
WIKI_VERSION_MINOR=0



function composerInstallDocker () {  #  composerInstall:  Doing COMPOSER based installations
  printf "\n\n*** Doing COMPOSER based installations "

  # ensure we start with a clean DanteDynamicInstalls.php file as this file will autocollect loadings of installed extensions"
  rm -f DanteDynamicInstalls.php 
  echo \"<?php \" >> DanteDynamicInstalls.php 

## the following is braindamaged composer construction
## to find out, we must
## 1) run the below composer install commands interactively in a shell
## 2) wait for security confirmations and answer yes
## 3) look at config.allow-plugins in the composer.json file, which gets modified in consequence of this
## 4) add the elements added to composer.json into this shell file

# TODO: do we need to make this ourselves ??? really
# TODO: do we need to configure permissions locally AND globally ??? as above
# TODO: do we really need that --no-interaction here ??
# TODO: do we really need to mka ethe directory for bootstrap ourselves ??
# TODO:
# The skins autoregister in the installation routine, however Bootstrap does not. But then, Bootstrap must be loaded before some skins.
# Therefore we must FIRST do the installation THEN install Bootstrap and inject that into the settings and only then install the skins and inject them (as they will now no longer autoregister)

  # INSTALLING extensions
  echo "*** Installing some extension requirements"

  # Install markdown parser https://github.com/erusev/parsedown
  printf '*** Installing markdown: docker exec -w /${MOUNT}/${VOLUME_PATH} ${LAP_CONTAINER}   sh -c " COMPOSER=composer.local.json  composer require erusev/parsedown"'
  COMPOSER=composer.local.json  composer require erusev/parsedown

  # Install markdown-extra https://michelf.ca/projects/php-markdown/extra/
  COMPOSER=composer.local.json  composer require erusev/parsedown-extra

  # Install markdown-extended https://github.com/BenjaminHoegh/ParsedownExtended
  COMPOSER=composer.local.json  composer require benjaminhoegh/parsedown-extended

  # Install requirements for deepl integration in DantePresentations
  COMPOSER=composer.local.json  composer require deeplcom/deepl-php

  COMPOSER=composer.local.json composer require --no-update mediawiki/semantic-media-wiki

  printf "\n\n*** DONE installing extension requirements\n\n"
}


function initGit () {
  printf " * Ensuring proper git postbuffer size..."
    # https://stackoverflow.com/questions/21277806/fatal-early-eof-fatal-index-pack-failed/29355320#29355320
    git config --global http.postBuffer 524288000
    git config --global core.packedGitLimit 512m
    git config --global core.packedGitWindowSize 512m
    git config --global pack.deltaCacheSize 2047m
    git config --global pack.packSizeLimit 2047m
    git config --global pack.windowMemory 2047m
  printf " DONE\n"
}



function installExtensionGithub () { # INSTALL an extension which is hosted on github
  # EXAMPLE:   installExtensionGithub  https://github.com/kuenzign/WikiMarkdown  WikiMarkdown  main
  local URL=$1
  local NAME=$2
  local BRANCH=$3

  printf "\n*** INSTALLING EXTENSION ${NAME} from ${URL} using branch ${BRANCH} ...\n"

    printf " * Removing preexisting directory..."
      rm -Rf ${NAME}
    printf " DONE\n"

    printf "   Cloning ${URL} with branch ${BRANCH} into ${NAME} ..."
      git clone --depth 1 ${URL} --branch ${BRANCH} ${NAME}
    printf " DONE\n"

    printf "   Removing .git to save on space ..."
       rm -Rf .git
    printf " DONE\n"

    printf "   Injecting installation into DanteDynamicInstalls.php ..."
      echo "wfLoadExtension( '${NAME}' );" >> DanteDynamicInstalls.php 
    printf " DONE\n"
  printf "*** COMPLETED INSTALLING EXTENSION ${NAME} from ${URL} using branch ${BRANCH}\n\n"
}



#set -e

mkdir /var/www/html/wiki-dir
cd /var/www/html/wiki-dir

printf " *** Checking directory:\n"
  ls -al /var/www/html
printf " DONE checking directory\n\n"

WIKI_NAME=mediawiki-${WIKI_VERSION_MAJOR}.${WIKI_VERSION_MINOR}
LOCAL_FILE=${WIKI_NAME}.tar.gz

printf " *** Now getting wiki\n"
  wget https://releases.wikimedia.org/mediawiki/${WIKI_VERSION_MAJOR}/${WIKI_NAME}.tar.gz
printf " DONE getting\n\n"

printf "*** Unpacking to ${LOCAL_FILE} ..."
  tar --strip-components=1 -xzf ${LOCAL_FILE}
printf "DONE unpacking\n\n"


printf "\n** Configuring permissions for composer...\n"
  composer config --no-plugins allow-plugins.wikimedia/composer-merge-plugin true
  composer config --no-plugins allow-plugins.composer/package-versions-deprecated true
  composer config --no-plugins allow-plugins.composer/installers true
  echo '{}' > composer.local.json    # need the file to exist before being able to configure
  COMPOSER=composer.local.json composer config --no-plugins allow-plugins.wikimedia/composer-merge-plugin true
  COMPOSER=composer.local.json composer config --no-plugins allow-plugins.composer/package-versions-deprecated true
  COMPOSER=composer.local.json composer config --no-plugins allow-plugins.composer/installers true
printf "\nDONE configuring permissions for composer\n"


printf "\n *** Installing extensions...\n"
  cd extensions

  installExtensionGithub  https://github.com/kuenzign/WikiMarkdown                                        WikiMarkdown        main
  installExtensionGithub  https://github.com/wikimedia/mediawiki-extensions-MobileFrontend                MobileFrontend      REL1_39
#  installExtensionGithub  https://github.com/labster/HideSection/                                         HideSection master
  installExtensionGithub  https://github.com/wikimedia/mediawiki-extensions-RandomSelection               RandomSelection     REL1_39
  installExtensionGithub  https://github.com/wikimedia/mediawiki-extensions-LabeledSectionTransclusion    LabeledSectionTransclusion   REL1_39
  installExtensionGithub  https://github.com/wikimedia/mediawiki-extensions-RevisionSlider                RevisionSlider   REL1_39
  installExtensionGithub https://github.com/wikimedia/mediawiki-extensions-NativeSvgHandler               NativeSvgHandler  REL1_39
  installExtensionGithub https://github.com/wikimedia/mediawiki-extensions-UniversalLanguageSelector       UniversalLanguageSelector  REL1_39

#  installExtensionGithub https://github.com/wikimedia/mediawiki-extensions-DrawioEditor                   DrawioEditor REL1_39
# This extension is broken currently
#  Use my own version - see my mediawiki-extensions-DrawioEditor Patch
  installExtensionGithub https://github.com/clecap/mediawiki-extensions-DrawioEditor                      DrawioEditor master
  wget https://raw.githubusercontent.com/clecap/mediawiki-extensions-DrawioEditor/master/PATCH-UploadedFile.php -O includes/libs/ParamValidator/Util/UploadedFile.php
  wget https://raw.githubusercontent.com/clecap/mediawiki-extensions-DrawioEditor/master/PATCH-UploadBase.php -O includes/upload/UploadBase.php

##  looks like this extension is broken
##  installExtensionGithub https://github.com/wikimedia/mediawiki-extensions-WikEdDiff WikEdDiff REL1_39
##  The following is broken currently in REL1_38 only, might be fine in higher releases

  installExtensionGithub https://github.com/Universal-Omega/DynamicPageList3 DynamicPageList3 REL1_39

##  installExtensionGithub https://github.com/clecap/DynamicPageList3 DynamicPageList3 master

###### HACK: see README-DynamicPageList3-Clemens.md in TOPD_DIR/own for more details.
##  docker cp $TOP_DIR/own/DynamicPageList3/ ${LAP_CONTAINER}:/${MOUNT}/${VOLUME_PATH}/extensions

### currently to be done manually 
###  installExtensionGithub  https://github.com/clecap/Parsifal  Parsifal  dante

  installExtensionGithub   https://github.com/wikimedia/mediawiki-extensions-WikiCategoryTagCloud  WikiCategoryTagCloud  REL1_39
 
  installExtensionGithub https://github.com/wikimedia/mediawiki-extensions-Cargo Cargo REL1_39



printf " DONE installing extensions\n\n"

cd ..


printf "\n\n*** Doing a composer update on the global file\n\n"
  composer update
printf "\n\n***DONE with composerUpdate \n\n"


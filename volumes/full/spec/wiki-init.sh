#!/bin/bash

# This is a set of library functions for initializing the DYNAMICAL and DATABSE parts of a mediawiki, wordpress or similar system.
#
# ASSUMPTIONS:  A running configuration with a DB and an LAP container
#
# The file area may be a volume or a directory.
#

# parameters:
# 
#  DB_USER    Database User          (may be standard such as user0023)
#  DB_PASS    Database Password
#  WK_USER    Wiki Admin User        (should be free choice)
#  WK_PASS    Wiki Admin Password
#

# region  *** USAGE and COMMAND LINE PARSING
### Command Line Parameters can be used to override choices made in configuration files
#   This is particularly helpful for localhost based instances for in place edit scenarios
#
usage() {
  echo "Usage: $0 "
  echo "  --site-server     manual override of the site server (eg:  http://localhost:8080)"
}


# get directory where this script resides, wherever it is called from
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
TOP_DIR="${DIR}/../../../"


printf "\n\n*** reading in the script library..."
  source ${TOP_DIR}/volumes/full/spec/script-library.sh
printf "DONE\n\n"

printf "\n\n*** Ensure buffer is large enough on a global scale in any case\..."
  git config --global http.postBuffer 524288000
printf "DONE\n\n"

##
## obtain some parameters from a file
##
printf "*** Reading customize-PRIVATE.sh..."
  source ${DIR}/../../../conf/customize-PRIVATE.sh
printf "DONE\n\n"




# region  DEFINING certain global constants

# mount point of the volume or directory
MOUNT="/var/www/html"

# Names of the images which we assume are running
LAP_CONTAINER=my-lap-container
DB_CONTAINER=my-mysql

# endregion





function composerPermissions () {
  #  We must adjust the global configuration file of composer and the loca configuration file of composer to permit the use of certain plugins.
  #  The list of these plugins we must get form error messages in the composer runs

  printf "\n** Configuring permissions for composer\n"

    docker exec -w /${MOUNT}/${VOLUME_PATH} ${LAP_CONTAINER}   sh -c " composer config --no-plugins allow-plugins.wikimedia/composer-merge-plugin true       "
    docker exec -w /${MOUNT}/${VOLUME_PATH} ${LAP_CONTAINER}   sh -c " composer config --no-plugins allow-plugins.composer/package-versions-deprecated true  "
    docker exec -w /${MOUNT}/${VOLUME_PATH} ${LAP_CONTAINER}   sh -c " composer config --no-plugins allow-plugins.composer/installers true  "  

    docker exec -w /${MOUNT}/${VOLUME_PATH} ${LAP_CONTAINER}   sh -c " echo '{}' > composer.local.json"    # need the file to exist before being able to configure

    docker exec -w /${MOUNT}/${VOLUME_PATH} ${LAP_CONTAINER}   sh -c " COMPOSER=${MOUNT}/${VOLUME_PATH}/composer.local.json composer config --no-plugins allow-plugins.wikimedia/composer-merge-plugin true       "
    docker exec -w /${MOUNT}/${VOLUME_PATH} ${LAP_CONTAINER}   sh -c " COMPOSER=${MOUNT}/${VOLUME_PATH}/composer.local.json composer config --no-plugins allow-plugins.composer/package-versions-deprecated true  "
    docker exec -w /${MOUNT}/${VOLUME_PATH} ${LAP_CONTAINER}   sh -c " COMPOSER=${MOUNT}/${VOLUME_PATH}/composer.local.json composer config --no-plugins allow-plugins.composer/installers true  "  

  printf "\nDONE configuring permissions for composer\n"
}


# region installExtensionGithub ()   
# INSTALL an extension which is hosted on github
# EXAMPLE:   installExtensionGithub  https://github.com/kuenzign/WikiMarkdown  WikiMarkdown  main
installExtensionGithub () {
  local URL=$1
  local NAME=$2
  local BRANCH=$3

# MOUNT
# VOLUME_PATH
# LAP_CONTAINER

  printf "\n*** INSTALLING EXTENSION ${NAME} from ${URL} using branch ${BRANCH} ...\n"

  printf " * Ensuring proper git postbuffer size\n"
    # https://stackoverflow.com/questions/21277806/fatal-early-eof-fatal-index-pack-failed/29355320#29355320
    docker exec -w /${MOUNT}/${VOLUME_PATH}/extensions/ ${LAP_CONTAINER}  sh -c "git config --global http.postBuffer 524288000"
    docker exec -w /${MOUNT}/${VOLUME_PATH}/extensions/ ${LAP_CONTAINER}  sh -c "git config --global core.packedGitLimit 512m"
    docker exec -w /${MOUNT}/${VOLUME_PATH}/extensions/ ${LAP_CONTAINER}  sh -c "git config --global core.packedGitWindowSize 512m"
    docker exec -w /${MOUNT}/${VOLUME_PATH}/extensions/ ${LAP_CONTAINER}  sh -c "git config --global pack.deltaCacheSize 2047m"
    docker exec -w /${MOUNT}/${VOLUME_PATH}/extensions/ ${LAP_CONTAINER}  sh -c "git config --global pack.packSizeLimit 2047m"
    docker exec -w /${MOUNT}/${VOLUME_PATH}/extensions/ ${LAP_CONTAINER}  sh -c "git config --global pack.windowMemory 2047m"
  printf " DONE\n"

  printf "   Removing preexisting directory\n"
  docker exec -w /${MOUNT}/${VOLUME_PATH}/extensions/ ${LAP_CONTAINER}  sh -c "rm -Rf ${NAME} "
  printf "   Cloning ${URL} with branch ${BRANCH} into ${NAME}\n"
    docker exec -w /${MOUNT}/${VOLUME_PATH}/extensions ${LAP_CONTAINER}          sh -c " git clone --depth 1 ${URL} --branch ${BRANCH} ${NAME} "

  printf "   Removing .git to save on space\n"
    docker exec -w /${MOUNT}/${VOLUME_PATH}/extensions/${NAME} ${LAP_CONTAINER}  sh -c "rm -Rf .git "

  printf "   Injecting installation into DanteDynamicInstalls.php\n"
    docker exec -w /${MOUNT}/${VOLUME_PATH} ${LAP_CONTAINER} sh -c "echo \"wfLoadExtension( '${NAME}' );\" >> DanteDynamicInstalls.php "
  printf "*** COMPLETED INSTALLING EXTENSION ${NAME} from ${URL} using branch ${BRANCH}\n\n"
}


# region installExtensionGerrit ()   
# INSTALL an extension which is hosted on gerrit
installExtensionGerrit () {
  NAME=$1
  RELEASE=$2
  docker exec -w /${MOUNT}/${VOLUME_PATH}/extensions ${LAP_CONTAINER}   sh -c " git clone https://gerrit.wikimedia.org/r/mediawiki/extensions/${NAME} --branch ${RELEASE} ${NAME} "
  docker exec -w /${MOUNT}/${VOLUME_PATH}/extensions/${NAME} sh -c "rm -Rf .git "
}
# endregion


composerInstall () {  #  composerInstall:  Doing COMPOSER based installations
  printf "\n\n*** Doing COMPOSER based installations "

  # ensure we start with a clean DanteDynamicInstalls.php file as this file will autocollect loadings of installed extensions"
  docker exec -w /${MOUNT}/${VOLUME_PATH} ${LAP_CONTAINER} sh -c "rm -f DanteDynamicInstalls.php "
  docker exec -w /${MOUNT}/${VOLUME_PATH} ${LAP_CONTAINER} sh -c " echo \"<?php \" >> DanteDynamicInstalls.php "

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
  docker exec -w /${MOUNT}/${VOLUME_PATH} ${LAP_CONTAINER}   sh -c " COMPOSER=composer.local.json  composer require erusev/parsedown"

  # Install markdown-extra https://michelf.ca/projects/php-markdown/extra/
  docker exec -w /${MOUNT}/${VOLUME_PATH} ${LAP_CONTAINER}   sh -c " COMPOSER=composer.local.json  composer require erusev/parsedown-extra"

  # Install markdown-extended https://github.com/BenjaminHoegh/ParsedownExtended
  docker exec -w /${MOUNT}/${VOLUME_PATH} ${LAP_CONTAINER}   sh -c " COMPOSER=composer.local.json  composer require benjaminhoegh/parsedown-extended"

  # Install requirements for deepl integration in DantePresentations
  docker exec -w /${MOUNT}/${VOLUME_PATH} ${LAP_CONTAINER}   sh -c " COMPOSER=composer.local.json  composer require deeplcom/deepl-php"

  printf "\n\n*** DONE installing extension requirements\n\n"


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
  docker exec -w /${MOUNT}/${VOLUME_PATH}/ ${LAP_CONTAINER}  sh -c "wget https://raw.githubusercontent.com/clecap/mediawiki-extensions-DrawioEditor/master/PATCH-UploadedFile.php -O includes/libs/ParamValidator/Util/UploadedFile.php"
  docker exec -w /${MOUNT}/${VOLUME_PATH}/ ${LAP_CONTAINER}  sh -c "wget https://raw.githubusercontent.com/clecap/mediawiki-extensions-DrawioEditor/master/PATCH-UploadBase.php -O includes/upload/UploadBase.php"


##  looks like this extension is broken
##  installExtensionGithub https://github.com/wikimedia/mediawiki-extensions-WikEdDiff WikEdDiff REL1_39

##  The following is broken currently in REL1_38 only, might be fine in higher releases

installExtensionGithub https://github.com/Universal-Omega/DynamicPageList3 DynamicPageList3 REL1_39

##  installExtensionGithub https://github.com/clecap/DynamicPageList3 DynamicPageList3 master

###### HACK: see README-DynamicPageList3-Clemens.md in TOPD_DIR/own for more details.
##  docker cp $TOP_DIR/own/DynamicPageList3/ ${LAP_CONTAINER}:/${MOUNT}/${VOLUME_PATH}/extensions

### currently to be done manually 
###  installExtensionGithub  https://github.com/clecap/Parsifal  Parsifal  dante

  echo "DONE installing extensions"
  echo ""

  printf "\n\n*** Doing a composer update on the global file\n\n"
  docker exec -w /${MOUNT}/${VOLUME_PATH} ${LAP_CONTAINER}   sh -c " composer update"
  printf "\n\n***DONE with composerInstall \n\n"
}
# endregion





# region patchingForChameleon: Chameleon skin patch
# Chameleon skin is autodetected in the install script, but extensions are not autodetected. However, chameleon
# requires the Bootstrap extension. Thus, in case we have chameleon autodetected we must pathc in loading Bootstrap
# beforehand, or the automagic install process does not run through.
# This patching must be done IF chameleon is installed and it must be done after the wiki installer produced LocalSettings.php
patchingForChameleon () {

#  docker exec -w /${MOUNT}/${VOLUME_PATH} ${LAP_CONTAINER} sed -i "s/wfLoadSkin( 'chameleon' );/wfLoadExtension( 'Bootstrap' ); wfLoadSkin( 'chameleon' ); ### patched by dante installer in wiki-init.sh /g" ${MOUNT}/${VOLUME_PATH}/LocalSettings.php
  docker exec -w /${MOUNT}/${VOLUME_PATH} ${LAP_CONTAINER} sh -c "sed \"s/wfLoadSkin( 'chameleon' );/wfLoadExtension( 'Bootstrap' ); wfLoadSkin( 'chameleon' ); ### patched by dante installer in wiki-init.sh /g\" LocalSettings.php > NEWLocalSettings.php"
  docker exec -w /${MOUNT}/${VOLUME_PATH} ${LAP_CONTAINER} sh -c "cp ${MOUNT}/${VOLUME_PATH}/NEWLocalSettings.php ${MOUNT}/${VOLUME_PATH}/LocalSettings.php"

}
# endregion


## for setting up wordpress, we start with a username 
## CAVE: wikis currently do this differently, by traversing the file system and picking up directories   ### TODO: make this uniform !!

## TODO: turn more stuff into parameter, particularly passwords and user names
initWP () {
  USERNAME=$1

  VERSION=6.1.1
  LOCALE=en_DB

  DB_NAME="WP_${USERNAME}"
  DB_USER="${USERNAME}"
  # CAVE: DB_USER must not contain a minus sign

  # TODO: This must be adjusted
  DB_PASS="password-wp"

  URL=https://localhost/wp-word

  # Wordpress Admin USer
  ADMIN_USER="wp-user"

  # This must be adjusted
  ADMIN_PASSWORD="password-admin"

  # TODO: This must be adjusted
  ADMIN_EMAIL="clemens@clemens-cap.de"

  # OS / Linux User for the file ownership
  LINUX_USER="lnx-wp-${USERNAME}"

## TODO: for security reasons we want a different user/pw on the web side than on the db side (the db side secures the data but is not open for web-side brute force attacks)

  # Name of the wp installation
  WP_TITLE="Adhuc Stat"

  # directory in which to build the Wordpress installation
  VOLUME_PATH="wp-${USERNAME}"

  # add database to DB system
  printf "\n** Generating database ${DB_NAME} and DB user ${DB_USER}\n"
  dropDatabase ${DB_NAME}  ${DB_CONTAINER}  ${MYSQL_ROOT_PASSWORD}

  printf "------- container ${DB_CONTAINER}"

  addDatabase ${DB_NAME} ${DB_USER} ${DB_PASS}  ${MYSQL_ROOT_PASSWORD}  ${DB_CONTAINER}
  printf "DONE generating database\n"

  printf "\n** Generating OS User ${LINUX_USER} for Wordpress\n"
  docker exec -w /${MOUNT}/${VOLUME_PATH} ${LAP_CONTAINER} adduser -D ${LINUX_USER}
  printf "DONE generating OS User\n"

  printf "\n** Downloading wordpress core version ${VERSION}\n"
  docker exec -w /${MOUNT}/${VOLUME_PATH} --user ${LINUX_USER} ${LAP_CONTAINER} ./wp-cli.phar core download --version=${VERSION}
  printf "DONE downloading wordpress core version ${VERSION}\n"

  printf "\n** Creating client configuration\n"
  docker exec -w /${MOUNT}/${VOLUME_PATH} --user ${LINUX_USER} ${LAP_CONTAINER} ./wp-cli.phar config create --force  --url=${URL} --dbhost=${DB_CONTAINER}  --dbname=${DB_NAME} --dbuser=${DB_USER} --dbpass=${DB_PASS} --locale=${LOCALE}
  printf "DONE creating client configuration\n"

  # --skip-email since we here do not have access to sendmail
  printf "\n** Installing core\n"
  docker exec -w /${MOUNT}/${VOLUME_PATH} --user ${LINUX_USER} ${LAP_CONTAINER} ./wp-cli.phar core install --url=${URL} --title="${WP_TITLE}" --admin_name=${ADMIN_USER} --admin_password=${ADMIN_PASSWORD} --admin_email=${ADMIN_EMAIL} --skip-email
  printf "DONE installing core\n"

#  docker exec -w /${MOUNT}/${VOLUME_PATH} --user ${LINUX_USER}  ${LAP_CONTAINER}  mkdir -p wp-content/uploads
#####  docker exec -w /${MOUNT}/${VOLUME_PATH} --user ${LINUX_USER}  ${LAP_CONTAINER}  chgrp web uploads/
#  docker exec -w /${MOUNT}/${VOLUME_PATH} --user ${LINUX_USER}  ${LAP_CONTAINER} chmod 775 uploads/

#  printf "\n** Setting permissions\n"
#  docker exec -w /${MOUNT}/${VOLUME_PATH} --user ${LINUX_USER}  ${LAP_CONTAINER}  chmod 600 wp-config.php
#  printf "\nDONE setting permissions\n"

}



# region  INITIALIZE    Initialization function for an individual WIKI
#
initialize () {
  DB_USER=$1

  DB_NAME="DB_${DB_USER}"
  DB_PASS="password-$1"
  WK_USER=$1
  WK_PASS="password-$1"

  # TODO: must offer possibility to use a real password
  printf "\n*** Initialize sees DB_USER=${DB_USER}, DB_PASS=${DB_PASS}, WK_USER=${WK_USER}, WK_PASS=${WK_PASS}\n\n"

  # path to the wiki inside of the volume
  VOLUME_PATH="wiki-${DB_USER}"

  printf "** Is ${MOUNT}/${VOLUME_PATH}/ a wiki directory?\n"
  docker exec ${LAP_CONTAINER} ls ${MOUNT}/${VOLUME_PATH}/index.php
  if [ "$?" == "0" ]; then
    printf "* Found index.php, probably yes, continuing\n\n"
  else 
    printf "* NO *** EXITING initializer for ${VOLUME_PATH}\n\n"
    return
  fi


  # composer must run before the installscript so that the installscript has all the available extensions ready
  # this is necessary, since the installscript does an autoregistration of some components, for example the installed skins
  composerPermissions
  composerInstall

  addDatabase ${DB_NAME} ${DB_USER} ${DB_PASS}  ${MYSQL_ROOT_PASSWORD}  ${DB_CONTAINER}
  docker exec ${LAP_CONTAINER} rm -f ${MOUNT}/${VOLUME_PATH}/LocalSettings.php      # remove to have a clean start for install routines, ignore if not existant
  runMWInstallScript "${MW_SITE_NAME}"  "${MW_SITE_SERVER}" "ACRONYM" "password-dir"

  addingReferenceToDante ${MOUNT}  ${VOLUME_PATH}  ${LAP_CONTAINER} 
  initialTemplates  
  minimalInitialContents
  touchLocalSettings

  printf "\nDONE   *** INITIALIZING WIKI ***\n\n"
}
##
## END of initialization function
##
# endregion



# region main  MAIN function of the shell script
##
main () {

  WIKIS="${DIR}/../content/wiki-"*        # collect list of wikis from existing directory structure
  printf "\n*** List of wiki subdirectories found: ${WIKIS} \n"

  for WIKI in ${WIKIS}
  do
    printf "\n*** Initializing WIKI: ${WIKI}\n"
    if [[ $WIKI =~ wiki-([a-zA-Z0-9_]+)$ ]]; 
    then 
      initialize ${BASH_REMATCH[1]}
    else 
      printf "\n*** Skipping ${WIKI} as it is not in proper format\n" 
    fi
  done

  printf "*** We completed the entire wiki-init.sh script ***\n\n"
  printf "*** The Wiki is available at ${MW_SITE_SERVER} \n\n"
}


main 
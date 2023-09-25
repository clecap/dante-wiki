#!/bin/sh

## the following variables are exported into this script:
#
# DIR_NAME      we are copying from  volumes/${DIR_NAME}/
# VOLUME_NAME   we are copying to VOLUME_NAME
# VOLUME_PATH   we are copying to VOLUME_PATH in VOLUME_NAME

#  TEMP: Name of the temporary busybox container which does the copying
#  MOUNT: where the volume is mounted to the temporary copying container

## define the wiki version we want to use
WIKI_VERSION_MAJOR=1.37
WIKI_VERSION_MINOR=0

## derived 
WIKI_NAME=mediawiki-${WIKI_VERSION_MAJOR}.${WIKI_VERSION_MINOR}

##
## Install Mediawiki files
##
docker exec -w /${MOUNT}/${VOLUME_PATH} ${TEMP} wget https://releases.wikimedia.org/mediawiki/${WIKI_VERSION_MAJOR}/${WIKI_NAME}.tar.gz;
docker exec -w /${MOUNT}/${VOLUME_PATH} ${TEMP} tar --strip-components=1 -xvzf ${WIKI_NAME}.tar.gz
docker exec -w /${MOUNT}/${VOLUME_PATH} ${TEMP} rm ./${WIKI_NAME}.tar.gz
docker exec -w /${MOUNT}/${VOLUME_PATH} ${TEMP} mv ${WIKI_NAME}/*.* /${MOUNT}/${VOLUME_PATH}



##
## Install Dantewiki difference
##
#docker exec -w /${MOUNT}/${VOLUME_PATH} git clone "https://github.com/clecap/dante-delta.git" 

##### define the extensions we want to use and the specific branches we will use of them and load them
# Install Mediawiki extensions (ADD LATER or rather do it via a COPY below)
#  git clone "https://gerrit.wikimedia.org/r/mediawiki/skins/MinervaNeue" skins/MinervaNeue; \
#  git clone "https://gerrit.wikimedia.org/r/mediawiki/extensions/MobileFrontend" extensions/MobileFrontend; \
# curl --remote-name https://extdist.wmflabs.org/dist/extensions/CategoryTree-REL1_32-5866bb9.tar.gz
# tar -xzf CategoryTree-REL1_32-5866bb9.tar.gz -C /var/www/html/extensions
# ENSURE directory. permissions and ownership


## docker exec -w /${MOUNT} ${TEMP} chown -R www-data:www-data 

# Copy in PHP configuration file local version for our version of PHP; 
# we need this for apache2 and for cli (cli for the configuration script of LocalSettings.php)
#COPY mediawiki-php.ini /etc/php/7.4/apache2/conf.d/mediawiki-php.ini
#COPY mediawiki-php.ini /etc/php/7.4/cli/conf.d/mediawiki-php.ini

# Copy in some extensions (especially DynamicPageList3, which proved a bit tricky regarding some aspects)
##docker exec -w /${MOUNT} ${TEMP} cp -r volumes/${VOLUME}/DynamicPageList3 /${MOUNT}/${WIKI_NAME}/extensions/DynamicPageList3

# copy in an initialization shell command; will be run by bin/run.sh
##docker exec -w /${MOUNT} ${TEMP} cp initialize.sh /${MOUNT}/initialize.sh
##docker exec -w /${MOUNT} ${TEMP} chmod 755 /${MOUNT}/initialize.sh

# copy in some initial content pages for the wiki; will be installed by initialize.sh which will be run by bin/run.sh
##echo -n "Copying initial content pages..."
##docker exec -w /${MOUNT} ${TEMP} mkdir       /${MOUNT}/initial-contents
##docker exec -w /${MOUNT} ${TEMP} chmod 755   /${MOUNT}/initial-contents
##docker exec -w /${MOUNT} ${TEMP} cp -r initial-contents/  ${TEMP}:/${MOUNT}/initial-contents
echo "...DONE"




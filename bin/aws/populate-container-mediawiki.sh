#!/bin/sh

## shell script for generating a container with files ready for mediawik

VOLUME_NAME=temporary-test-volume

## name of a temporary container
TEMP=temporary-container

# TODO: fix this 
FAMILY_NAME=lamp

docker stop ${TEMP}
docker rm ${TEMP}

echo -n "Removing volume ${VOLUME_NAME}..."
docker volume rm ${VOLUME_NAME}
echo "DONE"

docker run --name ${TEMP} -d -t --volume ${VOLUME_NAME}:/daten alpine

# -w fixes the working directory 
#docker exec -w /daten ${TEMP} apk add ca-certificates
#docker exec -w /daten ${TEMP} wget --no-check-certificate https://releases.wikimedia.org/mediawiki/1.37/mediawiki-1.37.0.tar.gz

# docker exec takes only one command; sh -c is that one command; use string continuation then
docker exec -w /daten ${TEMP} sh -c "
  apk add ca-certificates;
  wget --no-check-certificate https://releases.wikimedia.org/mediawiki/1.37/mediawiki-1.37.0.tar.gz;

"

docker exec -w /daten ${TEMP} tar -xvzf mediawiki-1.37.0.tar.gz
docker exec -w /daten ${TEMP} rm mediawiki-1.37.0.tar.gz
#docker exec -w /daten/mediawiki-1.37.0 ${TEMP} mv * .. 
#docker exec -w /daten/mediawiki-1.37.0 ${TEMP} mv .* .. 
#docker exec -w /daten ${TEMP} rmdir mediawiki-1.37.0

#echo "copying..........................."

docker cp ${FAMILY_NAME}/efs/* ${TEMP}:/daten

# Install Mediawiki extensions (ADD LATER or rather do it via a COPY below)
##  git clone "https://gerrit.wikimedia.org/r/mediawiki/skins/MinervaNeue" skins/MinervaNeue; \
##  git clone "https://gerrit.wikimedia.org/r/mediawiki/extensions/MobileFrontend" extensions/MobileFrontend; \
## curl --remote-name https://extdist.wmflabs.org/dist/extensions/CategoryTree-REL1_32-5866bb9.tar.gz
## tar -xzf CategoryTree-REL1_32-5866bb9.tar.gz -C /var/www/html/extensions
# ENSURE directory. permissions and ownership
#mkdir -p /var/www/images;   \
#chmod 755 /var/www/images;  \
#chown -R www-data:www-data /var/www/html; \ 

# Copy in some extensions (especially DynamicPageList3, which proved a bit tricky regarding some aspects)
#COPY DynamicPageList3 /var/www/html/extensions/DynamicPageList3

# copy in an initialization shell command; will be run by bin/run.sh
#COPY initialize.sh /initialize.sh
#RUN chmod 755 /initialize.sh

# copy in some initial content pages for the wiki; will be installed by initialize.sh which will be run by bin/run.sh
#RUN mkdir /opt/initial-contents
#COPY initial-contents/* /opt/initial-contents








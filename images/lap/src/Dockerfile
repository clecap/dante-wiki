FROM tex

WORKDIR /tmp

# independently of what we find as shell setting in the base, we enforce /bin/bash
# this is necessary for some of the commands we use
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Install necessary packages
#   git          get proper hashes in Special:Version and in other places
#   imagemagick  THUMBNAIL support in mediawiki
#   DEFAULT-mysql-client      make dumps and restores via webserver interaction and via mediawiki special pages
#   msmtp             write simple mails to inform about backup job completion and more
#   php-curl:   must include this for the composer to run faster


RUN \
#   ensure docker desktop tab opens with a bash allowing dommand line editing and noy with sh or dash which does not 
    rm /bin/sh && \
    ln -sf /bin/bash /bin/sh && \
#   update apt-get and start installation
    apt-get update && \
    apt-get install -y   --no-install-recommends apache2 ca-certificates apache2-utils openssl && \
    apt-get install -y   --no-install-recommends php && \
    apt-get install -y   --no-install-recommends php-common php-mysqli php-intl php-apcu php-mbstring php- php-gd php-json php-xml php-bcmath php-tokenizer php-igbinary php-opcache php-pear php-curl && \
    apt-get install -y   --no-install-recommends default-mysql-client           && \
    apt-get install -y   --no-install-recommends php-fpm                        && \
    apt-get install -y   --no-install-recommends wget curl unzip git diffutils  && \
#   vim:        it is very convenient to have a vi editor in place for development inside of the container
    apt-get install -y   --no-install-recommends vim                            && \
#   prevent hints about the default branch master TODO: put into /etc/git ????
    git config --global init.defaultBranch master && \
    apt-get install -y   --no-install-recommends imagemagick netpbm djvulibre-bin librsvg2-bin xpdf mscgen msmtp gnuplot-nox graphviz && \
    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer && \
    apt-get install -y --no-install-recommends php-dev make && \
    pecl channel-update pecl.php.net && \
    pecl install ds && \
#  Get python and pip and then PYGMENTS for supporting TeX and Parsifal
    apt-get install -y --no-install-recommends python3 python3-pip && \
    ln -sf python3 /usr/bin/python && \
    apt-get install -y --no-install-recommends python3-setuptools 
#
## Install pymupdf
#
#    1) Installations with pip should use a virtual python environment or a --break-system-package (which is not recommended)
#    2) For some reason the active shell has no source command and we need to switch to bash
#    3) This also is an issue when the install triggers for python3.11-venv are activated

RUN apt-get install -y --no-install-recommends python3.11-venv  && \
    cd /opt && \
    python3 -m venv myenv && \
    source myenv/bin/activate && \
    /opt/myenv/bin/pip3 install --no-cache-dir pymupdf && \
    exit && \
## TODO: can we later clear up /opt or do we have to keep it ???
## AMAZON CLOUD COMMAND LINE (for backup)
    cd /tmp && \
    curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip -q awscliv2.zip && \
    ./aws/install && \
    rm -rf awscliv2.zip aws && \
## FINAL CLEANUP
    apt-get purge -y php-dev build-base linux-headers && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /usr/share/doc \
      /usr/share/man \
      /usr/share/locale/* \
      /usr/share/info \
      /var/cache/debconf/*-old \
      /var/lib/apt/lists/* \
      /var/lib/dpkg/*-old \
      /var/lib/dpkg/info/* \
      /var/cache/apt/* \
      /var/cache/man/* \
      /tmp/*


# Set up args (does not create a new layer but provides formal symbols for the process)
ARG MEDIAWIKI_VERSION=1.39.0
ARG MEDIAWIKI_TARBALL=mediawiki-$MEDIAWIKI_VERSION.tar.gz
ARG MEDIAWIKI_URL=https://releases.wikimedia.org/mediawiki/1.39/$MEDIAWIKI_TARBALL
ARG TARGET=/wiki-dir

ENV COMPOSER_ROOT_VERSION=${MEDIAWIKI_VERSION}


ARG TOP_PATH=/var/www/html/wiki-dir

# Download and extract MediaWiki
RUN curl -o /tmp/$MEDIAWIKI_TARBALL $MEDIAWIKI_URL      && \
    tar -xzf /tmp/$MEDIAWIKI_TARBALL -C /tmp   && \
    rm /tmp/$MEDIAWIKI_TARBALL && \
    mv /tmp/mediawiki-$MEDIAWIKI_VERSION /var/www/html/${TARGET} && \
  rm -Rf /var/www/html/${TARGET}/skins/Refreshed/.git




## we need to open composer or we get problems with composer permission details
ENV COMPOSER_ALLOW_SUPERUSER=1


#  We must adjust the global configuration file of composer and the loca configuration file of composer to permit the use of certain plugins.
#  The list of these plugins we must get form error messages in the composer runs

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

############################################ phpinfo.php rausnehmen !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!


# composer wants us to do stuff as non-root  problem: git then cannot write to var www .git 
# USER www-data

WORKDIR ${TOP_PATH}

RUN composer config --no-plugins allow-plugins.wikimedia/composer-merge-plugin true       

RUN  composer config --no-plugins allow-plugins.composer/package-versions-deprecated true  && \
    composer config --no-plugins allow-plugins.composer/installers true

# need the file to exist before being able to configure
RUN echo '{}' > ${TOP_PATH}/composer.local.json    && \
       composer config --global allow-plugins true && \
###    COMPOSER=${TOP_PATH}/composer.local.json composer config --no-plugins allow-plugins.wikimedia/composer-merge-plugin true   && \
###    COMPOSER=${TOP_PATH}/composer.local.json composer config --no-plugins allow-plugins.composer/package-versions-deprecated true  && \
###    COMPOSER=${TOP_PATH}/composer.local.json composer config --no-plugins allow-plugins.composer/installers true  && \
    echo "<?php " > ${TOP_PATH}/DanteDynamicInstalls.php && \
#   Install markdown parser https://github.com/erusev/parsedown
    COMPOSER=${TOP_PATH}/composer.local.json  composer require erusev/parsedown && \
    COMPOSER=${TOP_PATH}/composer.local.json  composer require erusev/parsedown && \
#   Install markdown-extra https://michelf.ca/projects/php-markdown/extra/
    COMPOSER=${TOP_PATH}/composer.local.json  composer require erusev/parsedown-extra && \
    COMPOSER=${TOP_PATH}/composer.local.json  composer require benjaminhoegh/parsedown-extended 
#   Install requirements for deepl integration in DantePresentations
## TODO: has some small dependency problem which we solve later
##    COMPOSER=${TOP_PATH}/composer.local.json  composer require deeplcom/deepl-php

##
## COPY in docker context
##
COPY . /

RUN /home/dante/dantescript/install-extension-github.sh  ${TOP_PATH}  https://github.com/kuenzign/WikiMarkdown                                        WikiMarkdown                 main && \
    /home/dante/dantescript/install-extension-github.sh  ${TOP_PATH}  https://github.com/wikimedia/mediawiki-extensions-MobileFrontend                MobileFrontend               REL1_39 && \
    /home/dante/dantescript/install-extension-github.sh  ${TOP_PATH}  https://github.com/wikimedia/mediawiki-extensions-RandomSelection               RandomSelection              REL1_39  && \
    /home/dante/dantescript/install-extension-github.sh  ${TOP_PATH}  https://github.com/wikimedia/mediawiki-extensions-LabeledSectionTransclusion    LabeledSectionTransclusion   REL1_39 && \
    /home/dante/dantescript/install-extension-github.sh  ${TOP_PATH}  https://github.com/wikimedia/mediawiki-extensions-RevisionSlider                RevisionSlider               REL1_39 && \
    /home/dante/dantescript/install-extension-github.sh  ${TOP_PATH}  https://github.com/wikimedia/mediawiki-extensions-NativeSvgHandler              NativeSvgHandler             REL1_39 && \
    /home/dante/dantescript/install-extension-github.sh  ${TOP_PATH}  https://github.com/wikimedia/mediawiki-extensions-UniversalLanguageSelector     UniversalLanguageSelector    REL1_39 && \
#  installExtensionGithub  https://github.com/labster/HideSection/                                         HideSection master
#  installExtensionGithub https://github.com/wikimedia/mediawiki-extensions-DrawioEditor                   DrawioEditor REL1_39
# This extension is broken currently
#  Use my own version - see my mediawiki-extensions-DrawioEditor Patch
    /home/dante/dantescript/install-extension-github.sh  ${TOP_PATH}  https://github.com/clecap/mediawiki-extensions-DrawioEditor                      DrawioEditor                master && \
# PATHCES: ## TODO: maybe at a different place and not in dockerfile !!!
    wget https://raw.githubusercontent.com/clecap/mediawiki-extensions-DrawioEditor/master/PATCH-UploadedFile.php -O includes/libs/ParamValidator/Util/UploadedFile.php && \
    wget https://raw.githubusercontent.com/clecap/mediawiki-extensions-DrawioEditor/master/PATCH-UploadBase.php -O includes/upload/UploadBase.php   && \
##  looks like this extension is broken
##  installExtensionGithub https://github.com/wikimedia/mediawiki-extensions-WikEdDiff WikEdDiff REL1_39
##  The following is broken currently in REL1_38 only, might be fine in higher releases
    /home/dante/dantescript/install-extension-github.sh  ${TOP_PATH}  https://github.com/Universal-Omega/DynamicPageList3                  DynamicPageList3         REL1_39  && \
##  installExtensionGithub https://github.com/clecap/DynamicPageList3 DynamicPageList3 master
###### HACK: see README-DynamicPageList3-Clemens.md in TOPD_DIR/own for more details.
##  docker cp $TOP_DIR/own/DynamicPageList3/ ${LAP_CONTAINER}:/${MOUNT}/${VOLUME_PATH}/extensions
    /home/dante/dantescript/install-extension-github.sh  ${TOP_PATH}  https://github.com/wikimedia/mediawiki-extensions-WikiCategoryTagCloud  WikiCategoryTagCloud  REL1_39 && \
    composer update


RUN \
#   select intended operating mode
    a2dismod php8.2                 && \
    a2dismod mpm_prefork            && \
    a2enmod proxy                   && \ 
    a2enmod proxy_fcgi              && \
    a2enmod setenvif                && \
############################    a2enconf php-fpm                && \  ## TODO ??
    a2enmod mpm_event               && \
# remove default apache sites
    a2dissite 000-default.conf      && \
    a2dissite default-ssl.conf      && \
# remove some apache modules
    a2dismod userdir                && \
# configure apache for security
    a2enmod ssl                     && \
    a2enmod auth_basic              && \
    a2enmod auth_digest             && \
# configure apache for speed
    a2enmod cache                   && \
    a2enmod cache_disk              && \
    a2enmod headers                 && \
    a2enmod expires                 && \
    a2enmod deflate                 && \
    a2enmod http2                   && \
# configure apache for 
    a2enmod rewrite                 && \
    a2enmod alias                   && \
    a2enmod include


## 
## Adhere to default non-root user policy promoted by dockerhub
##
#  Create a non-root user and add to the sudo group
#  Set the home directory and working directory for the new user
#  Copy your application code to the container
#  Give non-root user ownership of the application files
#  Set the default user ## TODO: do we want this? is it compatible with the deletion strategies we need ???

# USER root


## TODO: do we really need this ???
RUN useradd -m dante && echo "dante:password" | chpasswd && adduser dante sudo

WORKDIR /home/dante
RUN chown -R dante:dante /home/dante

###### USER dante



##
## Default parameters for the entrypoint script below
##
CMD ["run-apache.sh"]

##
## Specify entrypoint, which will itself execute scripts provided as parameter
##
ENTRYPOINT ["/lap-entrypoint.sh"]









FROM debian:stable-20250407-slim

# FROM debian:stable-slim@sha256:382967fd7c35a0899ca3146b0b73d0791478fba2f71020c7aa8c27e3a4f26672 AS intermediary

##
## ARG / VARIABLE section  
#  Set up args (does not create a new layer but provides formal symbols for the process)
#

# Variable CTAN designates the site where to obtain texlive from.
#  We mmight want to set it to a different value when there is a problem with a site assigned by mirror.ctan.org
#  CTAN could be mirror.ctan.org
#  CTAN could also designate a specific mirror, such as ctan.net

ARG CTAN=ctan.net
ARG YEAR=2024

ARG MEDIAWIKI_VERSION=1.39.0
ARG MEDIAWIKI_TARBALL=mediawiki-$MEDIAWIKI_VERSION.tar.gz
ARG MEDIAWIKI_URL=https://releases.wikimedia.org/mediawiki/1.39/$MEDIAWIKI_TARBALL
ARG TARGET=/wiki-dir

ARG TOP_PATH=/var/www/html/wiki-dir


##
## LABEL section
##

LABEL maintainer="Clemens H. Cap"
LABEL copyright="(C) 2022-2025 Clemens H. Cap"
LABEL description="Dockerfile for Dantewiki"
LABEL dockerhub-url="https://hub.docker.com/repository/docker/clecap/dante"
LABEL git-url="https://github.com/clecap/dante"
LABEL vcs-url="https://github.com/clecap/dante"
LABEL license="AGPL 3"

##
## ENV section
##

ENV DEBIAN_FRONTEND=noninteractive  \
    LANG=C.UTF-8      \
    LC_ALL=C.UTF-8    \
    # ConTeXt cache can be created on runtime and does not need to increase image size  
    TEXLIVE_INSTALL_NO_CONTEXT_CACHE=1 \ 
    # As we will not install regular documentation why would we want to install perl docs…
    NOPERLDOC=1 \ 
    # 
    # the following environment variables are needed for TeX operations, for PARSIFAL and DANTEWIKI
    # 
    # main TeX directory
    TEXDIR=/usr/local/texlive/$YEAR  \
    # director for site-wide local files
    TEXMFLOCAL=/usr/local/texlive/texmf-local  \
    # directory for variable and automatically generated data
    TEXMFSYSVAR=/usr/local/texlive/$YEAR/texmf-var  \
    # directory for local configuration
    TEXMFSYSCONFIG=/usr/local/texlive/$YEAR/texmf-config \
    # personal directory for variable and automatically generated data
    TEXMFVAR=/var/www/.texlive$YEAR/texmf-var         \           
    # personal directory for local config
    TEXMFCONFIG=/var/www/.texlive$YEAR/texmf-config   \
    # directory for user specific files
    TEXMFHOME=/var/www/texmf       \
    # TEXINPUTS might be amended outside of the container as part of Parsifal etc.
    TEXINPUTS=/var/www/texinputs   \
    #  We are setting the path so that we can more easily exercise and test commands inside of a docker exec shell
    PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/local/texlive/$YEAR/bin/x86_64-linux:/bin: \
    # We must run composer as root, suppress warning and error messages about this
    COMPOSER_ROOT_VERSION=${MEDIAWIKI_VERSION}


WORKDIR /tmp

##
## TEX layer
##

## runtime dependencies:
# perl for some latex scripts
## build dependencies
# gnupg for verifying signature on texlive
# ca-certificates for the tex-live manager to identify partners

RUN apt-get update                                                                                     && \ 
    apt-get install -y  --no-install-recommends  perl                                                  && \
    apt-get install -y  --no-install-recommends  gnupg  curl  ca-certificates                          && \
    echo "*** *** *** downloading Texlive "                                                            && \
    curl https://$CTAN/systems/texlive/tlnet/install-tl-unx.tar.gz             -o /tmp/install-tl-unx.tar.gz             && \
    curl https://$CTAN/systems/texlive/tlnet/install-tl-unx.tar.gz.sha512      -o /tmp/install-tl-unx.tar.gz.sha512      && \
    curl https://$CTAN/systems/texlive/tlnet/install-tl-unx.tar.gz.sha512.asc  -o /tmp/install-tl-unx.tar.gz.sha512.asc  && \
    echo "*** *** *** downloading GPG key "                                                            && \
    curl https://www.tug.org/texlive/files/texlive.asc        -o /tmp/texlive.asc                                        && \
    echo "*** *** *** importing GPG key "                                                              && \
    gpg --import /tmp/texlive.asc                                                                      && \
    echo "*** *** *** Verifying signature on Texlive installer "                                       && \
    gpg --verify /tmp/install-tl-unx.tar.gz.sha512.asc /tmp/install-tl-unx.tar.gz.sha512               && \
    echo "*** *** *** Verifying hash value "                                                           && \
    sha512sum -c /tmp/install-tl-unx.tar.gz.sha512                                                     && \
    echo "*** *** *** Removing gnupg - no longer needed"                                               && \
    apt-get purge -y gnupg                                                                             && \
    gunzip /tmp/install-tl-unx.tar.gz                                                                  && \
    mkdir -p /tmp/install-tl                                                                           && \
    tar -xf /tmp/install-tl-unx.tar    -C /tmp/install-tl  --strip-components=1                        && \
    ls -alg /tmp && \
    ls -alg /tmp/install-tl && \
    # select full installation
    echo "*** *** *** Adjusting install profile "                                                      && \
    echo "selected_scheme scheme-full" > /tmp/install-tl/install.profile                               && \
    # do not install doc files
    echo "tlpdbopt_install_docfiles 0" >> /tmp/install-tl/install.profile                              && \
    # do not install src files
    echo "tlpdbopt_install_srcfiles 0" >> /tmp/install-tl/install.profile                              && \
    # do not know what this does but everybody does so (shitty approach, I know)
    echo "tlpdbopt_autobackup 0" >> install.profile                                                    && \
    # furthermore we want our symlinks in the system binary folder
    echo "tlpdbopt_sys_bin /usr/bin" >> /tmp/install-tl/install.profile                                && \
    # actually install TeX Live
    /tmp/install-tl/install-tl -profile /tmp/install-tl/install.profile                                && \
    #
    #  Adjust for vulnerabilities reported in sub-packages by docker scanner
    #
    tlmgr remove --force tlcockpit                                                                     && \
    tlmgr remove --force texplate                                                                      && \
    tlmgr remove --force arara                                                                         && \
    tlmgr remove --force latex2nemeth                                                                  && \
    echo "*** *** *** Update texlive database after force rmoval "                                     && \
    tlmgr update --self                                                                                && \
    tlmgr update --all                                                                                 && \
    #
    #
    echo "*** *** *** Verify Version "                                                                 && \
    tlmgr --version                                                                                    && \
    #
    #  Now cleanup
    #
    echo "*** *** *** Doing a layer cleanup "                                                          && \
    apt-get autoremove -y                                                                              && \
    apt-get clean                                                                                      && \
    rm -rf /usr/share/doc   \
      /usr/share/man        \
      /usr/share/locale/*   \
      /usr/share/info       \
      /var/cache/apt/*      \
      /var/cache/man/*      \
      /tmp/*

### CAVE: Do not delete the package files or later installation steps might be troubled
#      /var/cache/debconf/*-old \
#      /var/lib/apt/lists/* \
#      /var/lib/dpkg/*-old \
#      /var/lib/dpkg/info/* \

# independently of what we find as shell setting in the base, we enforce /bin/bash
# this is necessary for some of the commands we use
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

FROM intermediary AS dante

# Stuff we may clean at the end of each layer
ARG CLEAN_DOCKER_LAYER=" \
      /usr/share/doc   \
      /usr/share/man        \
      /usr/share/locale/*   \
      /usr/share/info       \
      /var/cache/debconf/*-old    \
      /var/lib/apt/lists/*        \
      /var/lib/dpkg/*-old         \
      /var/lib/dpkg/info/*        \
      /var/cache/apt/*            \
      /var/cache/man/*            \
      /tmp/* "

## Install necessary packages
#   git                       get proper hashes in Special:Version and in other places
#   imagemagick               THUMBNAIL support in mediawiki
#   default-mysql-client      make dumps and restores via webserver interaction and via mediawiki special pages
#   msmtp                     write simple mails to inform about backup job completion and more
#   php-curl:                 must include this for the composer to run faster

RUN \
    echo "*** *** *** Ensure docker desktop tab opens with a bash allowing command line editing  "                         && \ 
    rm /bin/sh                                                                                                             && \
    ln -sf /bin/bash /bin/sh                                                                                               && \
    echo "*** *** *** Generate target directories for the COPY operation below "                                           && \
    useradd -m dante && echo "dante:password" | chpasswd && adduser dante sudo                                             && \
    chown -R dante:dante /home/dante     



RUN \
    echo "*** *** *** Installations "                                                                                      && \
    apt-get update                                                                                                         && \
    apt-get install -y   --no-install-recommends  apache2  apache2-utils openssl                                           && \
    apt-get install -y   --no-install-recommends  php                                                                      && \
    apt-get install -y   --no-install-recommends  php-common  php-mysqli  php-intl  php-apcu  php-mbstring  php-gd         && \
    apt-get install -y   --no-install-recommends  php-json  php-xml  php-bcmath  php-tokenizer  php-igbinary  php-opcache  && \
    apt-get install -y   --no-install-recommends  php-pear php-curl                                                        && \
    apt-get install -y   --no-install-recommends  php-fpm                                                                  && \
    apt-get install -y   --no-install-recommends  default-mysql-client                                                     && \
    apt-get install -y   --no-install-recommends  curl  unzip  git  diffutils                                              && \
    apt-get install -y   --no-install-recommends  logrotate                                                                && \
    #   vim:        it is very convenient to have a vi editor in place for development inside of the container
    apt-get install -y   --no-install-recommends vim                                                                       && \
    #   configure git: prevent hints about the default branch master
    git config --global init.defaultBranch master                                                                          && \
    # install dependencies of mediawiki extensions we need
    # graphviz mscgen plantuml needed for extension:diagrams
    apt-get install -y   --no-install-recommends  imagemagick  netpbm  djvulibre-bin  librsvg2-bin  xpdf  mscgen           && \
#    apt-get install -y   --no-install-recommends  openjdk-17-jre-headless                                                 && \
#    apt-get install -y   --no-install-recommends  plantuml                                                                 && \
    apt-get install -y   --no-install-recommends  gnuplot-nox  graphviz                                                    && \
    apt-get install -y   --no-install-recommends  msmtp                                                                    && \
    echo "*** *** *** Installing composer "                                                                                && \
    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer                   && \
    echo "*** *** *** Installing ds, which needs pecl, which needs php-dev and make "                                      && \
    apt-get install -y --no-install-recommends  php-dev  make                                                              && \
    pecl channel-update pecl.php.net                                                                                       && \
    pecl install ds                                                                                                        && \
    apt-get purge -y  php-dev  make                                                                                        && \
    echo "*** *** *** Install python and pip and then pygments for supporting TeX and Parsifal "                           && \
    apt-get install -y --no-install-recommends  python3  python3-pip                                                       && \
    ln -sf python3 /usr/bin/python                                                                                         && \
    apt-get install -y --no-install-recommends  python3-setuptools                                                         && \
    echo "*** *** *** ldap utilities, required for apache ldap access "                                                    && \
    apt-get install -y --no-install-recommends  ldap-utils                                                                 && \
    echo "*** *** *** Configuring apache modules and environment "                                                         && \
#   select intended operating mode
    a2dismod php8.2                                                                                                        && \
    a2dismod mpm_prefork                                                                                                   && \
    a2enmod proxy                                                                                                          && \ 
    a2enmod proxy_fcgi                                                                                                     && \
    a2enmod setenvif                                                                                                       && \
    a2enmod mpm_event                                                                                                      && \
# remove default apache sites
    a2dissite 000-default.conf                                                                                             && \
    a2dissite default-ssl.conf                                                                                             && \
# remove some apache modules
    a2dismod userdir                                                                                                       && \
# configure apache for security
    a2enmod ssl                                                                                                            && \
    a2enmod auth_basic                                                                                                     && \
    a2enmod auth_digest                                                                                                    && \
# configure apache for speed
    a2enmod cache                                                                                                          && \
    a2enmod cache_disk                                                                                                     && \
    a2enmod headers                                                                                                        && \
    a2enmod expires                                                                                                        && \
    a2enmod deflate                                                                                                        && \
    a2enmod http2                                                                                                          && \
# configure apache for 
    a2enmod rewrite                                                                                                        && \
    a2enmod alias                                                                                                          && \
    a2enmod include                                                                                                        && \
    a2enmod authnz_ldap                                                                                                    && \
#   GNU parallel helps with fast copying 
    apt-get install -y --no-install-recommends parallel                                                                    && \
#   ssh client and rsync needed for doing backups           
    apt-get install -y --no-install-recommends openssh-client  rsync                                                       && \
## Install pymupdf
#
#    1) Installations with pip should use a virtual python environment or a --break-system-package (which is not recommended)
#    2) For some reason the active shell has no source command and we need to switch to bash
#    3) This also is an issue when the install triggers for python3.11-venv are activated
    echo "*** installing python stuff in virtual environment "                                                             && \
    apt-get install -y --no-install-recommends python3.11-venv                                                             && \
    python3 -m venv /opt/myenv                                                                                             && \
    source /opt/myenv/bin/activate                                                                                         && \
    /opt/myenv/bin/pip3 install --no-cache-dir pymupdf                                                                     && \
    # need wheel package for installing aws command line
    /opt/myenv/bin/pip3 install --no-cache-dir wheel                                                                       && \
    /opt/myenv/bin/pip3 install awscli --use-pep517                                                                        && \
   ################################################################################################################# /opt/myenv/bin/pip3 install pygments && \
    exit                                                                                                                   && \
    echo "*** *** *** Final cleanup "                                                                                      && \
    apt-get purge -y php-dev  build-base  linux-headers                                                                    && \
    apt-get autoremove -y                                                                                                  && \
    apt-get clean                                                                                                          && \
    rm -rf ${CLEAN_DOCKER_LAYER}


#  do not want auto-updates here
RUN \
    echo "*** preventing autoupdates"                                                  && \
    rm -f /etc/cron.daily/apt-compat                                                   && \
    echo "*** injecting the correct shell for www-data to enable a su to www-data "    && \
    chsh -s "/bin/bash" "www-data"                                                     && \
    echo "*** install and configure sudo "                                             && \
    apt-get update && apt-get install -y sudo                                          && \
    echo "www-data ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers                             && \
    chown -R www-data:www-data /var/www                                                && \
    apt-get clean                                                                      && \
    rm -rf ${CLEAN_DOCKER_LAYER}

# We do not want to have to chown files, as this is a time consuming operation when many files are involved
# Thus we switch to a different user for the following operations
USER www-data

RUN curl -o /tmp/$MEDIAWIKI_TARBALL $MEDIAWIKI_URL                 && \
    mkdir /var/www/html/${TARGET}                                   && \
    tar -xzf /tmp/$MEDIAWIKI_TARBALL -C /var/www/html/${TARGET} --strip-components=1    && \
    rm /tmp/$MEDIAWIKI_TARBALL                                     && \
    rm -Rf /var/www/html/${TARGET}/skins/Refreshed/.git

#   we need to open composer or we get problems with composer permission details
ENV COMPOSER_ALLOW_SUPERUSER=1

#  We must adjust the global configuration file of composer and the loca configuration file of composer to permit the use of certain plugins.

# The skins autoregister in the installation routine, however Bootstrap does not. But then, Bootstrap must be loaded before some skins.
# Therefore we must FIRST do the installation THEN install Bootstrap and inject that into the settings and only then install the skins and inject them (as they will now no longer autoregister)

############################################ phpinfo.php rausnehmen !!!!!

WORKDIR ${TOP_PATH}

RUN composer config --no-plugins allow-plugins.wikimedia/composer-merge-plugin true              && \
    composer config --no-plugins allow-plugins.composer/package-versions-deprecated true         && \
    composer config --no-plugins allow-plugins.composer/installers true                          && \
    echo "*** *** *** Need the file to exist before being able to configure"                     && \
    echo '{}' > ${TOP_PATH}/composer.local.json                                                  && \
    composer config --global allow-plugins true                                                  && \
    echo "<?php " > ${TOP_PATH}/DanteDynamicInstalls.php                                         && \
    echo "*** *** *** Install support library for markdown "                                     && \
    COMPOSER=${TOP_PATH}/composer.local.json  composer require erusev/parsedown                  && \
    COMPOSER=${TOP_PATH}/composer.local.json  composer require erusev/parsedown-extra            && \
    COMPOSER=${TOP_PATH}/composer.local.json  composer require benjaminhoegh/parsedown-extended  && \
#   The next 2 are required for openai / chatgpt integration
    COMPOSER=${TOP_PATH}/composer.local.json  composer require php-http/discovery                && \
    COMPOSER=${TOP_PATH}/composer.local.json  composer require openai-php/client                 && \
#   Install requirements for deepl integration in DantePresentations
    COMPOSER=${TOP_PATH}/composer.local.json  composer require  deeplcom/deepl-php               && \
    COMPOSER=${TOP_PATH}/composer.local.json  composer require  mediawiki/sub-page-list:~3.0


##
## COPY in docker context 
##
#  Do this as late as possible, since otherwise chenges in files require a redo of older dockerfile layers
#  Do this immediately before the files are really needed
# 

COPY . /


RUN  \
    /home/dante/dantescript/install-extension-github.sh  ${TOP_PATH}  https://github.com/kuenzign/WikiMarkdown                                        WikiMarkdown                 main       && \
    /home/dante/dantescript/install-extension-github.sh  ${TOP_PATH}  https://github.com/wikimedia/mediawiki-extensions-MobileFrontend                MobileFrontend               REL1_39    && \
    /home/dante/dantescript/install-extension-github.sh  ${TOP_PATH}  https://github.com/wikimedia/mediawiki-extensions-RandomSelection               RandomSelection              REL1_39    && \
    /home/dante/dantescript/install-extension-github.sh  ${TOP_PATH}  https://github.com/wikimedia/mediawiki-extensions-LabeledSectionTransclusion    LabeledSectionTransclusion   REL1_39    && \
    /home/dante/dantescript/install-extension-github.sh  ${TOP_PATH}  https://github.com/wikimedia/mediawiki-extensions-RevisionSlider                RevisionSlider               REL1_39    && \
    /home/dante/dantescript/install-extension-github.sh  ${TOP_PATH}  https://github.com/wikimedia/mediawiki-extensions-NativeSvgHandler              NativeSvgHandler             REL1_39    && \
    /home/dante/dantescript/install-extension-github.sh  ${TOP_PATH}  https://github.com/wikimedia/mediawiki-extensions-WikiCategoryTagCloud          WikiCategoryTagCloud         REL1_39    && \
#
#
#    /home/dante/dantescript/install-extension-github.sh  ${TOP_PATH}  https://github.com/samwilson/diagrams-extension                                 Diagrams                     master     && \
##  TODO: diagrams-extension master currently breaks claimed backwards compatibility with MW 1.39
#
    /home/dante/dantescript/install-extension-github.sh  ${TOP_PATH}  https://github.com/wikimedia/mediawiki-extensions-ReplaceText                   ReplaceText                  REL1_39    && \
    /home/dante/dantescript/install-extension-github.sh  ${TOP_PATH}  https://github.com/ProfessionalWiki/Network                                     Network                      master     && \
#
    /home/dante/dantescript/install-extension-github.sh  ${TOP_PATH}  https://github.com/wikimedia/mediawiki-extensions-SubPageList3                 SubPageList3                  REL1_39    && \
##    /home/dante/dantescript/install-extension-github.sh  ${TOP_PATH}  https://github.com/ProfessionalWiki/SubPageList                                SubPageList                   master     && \
#     SubPageList uses 
##    /home/dante/dantescript/install-extension-github.sh  ${TOP_PATH}  https://github.com/wikimedia/mediawiki-extensions-SubpageNavigation            SubpageNavigation             REL1_41    && \
#     SubpageNavigation not fully working in my 1.39 release.
#  installExtensionGithub  https://github.com/labster/HideSection/                                         HideSection master
#  TODO STUFF
#  looks like this extension is broken
#  installExtensionGithub https://github.com/wikimedia/mediawiki-extensions-WikEdDiff WikEdDiff REL1_39
#  The following is broken currently in REL1_38 only, might be fine in higher releases
    /home/dante/dantescript/install-extension-github.sh  ${TOP_PATH}  https://github.com/Universal-Omega/DynamicPageList3                             DynamicPageList3             REL1_39    && \
##  installExtensionGithub https://github.com/clecap/DynamicPageList3 DynamicPageList3 master
###### HACK: see README-DynamicPageList3-Clemens.md in TOPD_DIR/own for more details.
##  docker cp $TOP_DIR/own/DynamicPageList3/ ${LAP_CONTAINER}:/${MOUNT}/${VOLUME_PATH}/extensions
#
   composer update


## 
## Adhere to default non-root user policy promoted by dockerhub
##
#  Create a non-root user and add to the sudo group
#  Set the home directory and working directory for the new user
#  Copy your application code to the container
#  Give non-root user ownership of the application files
#  Set the default user ## TODO: do we want this? is it compatible with the deletion strategies we need ???


# Just kept in for debugging purposes during development 
# CMD ["sh", "-c", "while :; do sleep 2073600; done"]


##
## Default parameters for the entrypoint script below
##
CMD ["run-apache.sh"]

##
## Specify entrypoint, which will itself execute scripts provided as parameter
##

ENTRYPOINT ["/lap-entrypoint.sh"]



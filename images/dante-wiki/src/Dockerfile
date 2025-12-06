##
## Dante Wiki Dockerfile
##
#
#  We work in two stages.
#  Stage 1: Builds a system containing the required flavor of TeX and should not be changed often
#  Stage 2: Copies in TeX
#
#  NOTE 1:  Building TeX and copying it in can be cached better, is more robust and minimal
#           then building and deleting stuff
#  NOTE 2:  We install TeX not through the network installer but through the ISO image.
#           ISO image requires only one large file transfer instead of thousands of downloads (slow)
#           ISO image is more robust (only one network call may fail instead of many over a long period of time)
#           ISO image can be pulled fast, especially when building at dockerhub

# ==========================
#  Stage 1: TeX Live builder
# ==========================
FROM debian:stable-20251117-slim AS texlive-ready

##
## PARAMETERS for the build
##
#  NOTE: ARGs do NOT carry over automagically to later stages
#  NOTE: ARGs cannot be combined to reduce the number of layers
#
#  TL_YEAR: TeX Live year (used in paths and ISO name)
#  TEXLIVE_FPR: Expected fingerprint of the GPG public signing key
#                Key will be downloaded and checked against this fingerprint
#                So this amounts to some form of key pinning as well
ARG TL_YEAR=2025
ARG TEXLIVE_FPR=C78B82D8C79512F79CC0D7C80D5E5D9106BAB6BC

# We should derive subsequent argument values from here in ARG, since ENV values can be used only
# after the entire ENV command has been executed.
ARG  TL_FILE_NAME="texlive${TL_YEAR}.iso" 
ARG  TL_ISO_URL="https://mirror.ctan.org/systems/texlive/Images/${TL_FILE_NAME}" 

ENV  DEBIAN_FRONTEND=noninteractive   

# NOTE: set -eux; makes build more reliable
#           -e    exit on error, prevent silent failures
#           -u    treat unset variables as error; catches typos and missing variables
#           -x    print each command into the log before executing it
# NOTE: Each run starts a fresh shell, so need this at the beginning of every RUN

##
## DOWNLOAD stage. This takes some time (download 6GB) and so we do this as early as possible
##   to ensure it can be cached as often as possible
##
RUN \
  set -eux                                                                              && \
  apt-get update                                                                        && \ 
  apt-get install -y --no-install-recommends ca-certificates     && \
  apt-get install -y --no-install-recommends curl                                       && \
  rm -rf /var/lib/apt/lists/*                                                           && \
  mkdir -p /texlive                                                                     && \  
  echo "*** Downloading TeX Live ${TL_ISO_URL} to /texlive/${TL_FILE_NAME}"             && \
  curl -L "${TL_ISO_URL}" -o "/texlive/${TL_FILE_NAME}"                                 && \
  echo "DONE: Downloaded TeX Live iso "                                                 && \
  ls -l /texlive

##
## ENV Section
##
#   Use only one ENV command, as this reduces the number of layers
ENV \
  # URLs for ISO + signature; mirror.ctan.org will redirect to a nearby mirror
  # URL of the GPG key (silence hadolint, since this is a public key)
  # hadolint ignore=SC2154
  GPG_KEY_URL="https://www.tug.org/texlive/files/texlive.asc" \
  TEXLIVE_PUBKEY_ID="TeX Live Distribution <tex-live@tug.org>" 


##### WHAT ABOUT LINUXMUSL ???  TODO: REMOVE THIS FROM PARSIFAL config.php


##
## ARGs provided by the build system
##
# These are automatically set by buildx for each platform
ARG TARGETOS
ARG TARGETARCH
ARG TARGETVARIANT
ARG TARGETPLATFORM
ARG SOURCE_BRANCH
ARG SOURCE_COMMIT
ARG SOURCE_TAG
ARG DOCKERFILE_PATH
ARG IMAGE_NAME



# Install required tools and do some small minimal cleanup
# - downloading (curl)
# - signature verification (gnupg, ca-certificates)
# - installer runtime (perl, xz-utils for compressed archives)
# - extracting ISO (libarchive-tools -> bsdtar)
RUN                                                                 \ 
  set -eux                                                       && \
  apt-get update                                                 && \
  apt-get install -y --no-install-recommends gnupg               && \
  apt-get install -y --no-install-recommends perl                && \
  apt-get install -y --no-install-recommends xz-utils            && \
  apt-get install -y --no-install-recommends libarchive-tools    && \
  rm -rf /var/lib/apt/lists/*                                    && \
                                                                    \ 
  echo "*** Downloading TeXlive GPG key from ${GPG_KEY_URL}"     && \
  curl -fsSL "${GPG_KEY_URL}" -o /tmp/key.asc                    && \
  echo "DONE: Downloading TeXlive GPG key  from ${GPG_KEY_URL}"  && \
                                                                    \
  echo "*** Importing GPG key"                                   && \
  gpg --batch --import /tmp/key.asc                              && \
  echo "DONE: Importing the GPG key into the keyring"            && \
                                                                    \
  echo "*** Listing all keyring keys "                           && \
  gpg --list-keys --fingerprint                                  && \
  echo "*** Listing the key we need"                             && \
  gpg --list-keys "${TEXLIVE_PUBKEY_ID}"                         && \
                                                                    \
  echo "*** Obtaining the current fingerprint "                  && \
  ACTUAL_FPR="$(gpg --batch --with-colons --fingerprint "${TEXLIVE_PUBKEY_ID}" | awk -F: '/^fpr:/ {print $10; exit}')"  && \
  echo "DONE: Obtained current fingerprint:   $ACTUAL_FPR"       && \
                                                                    \
  echo "*** Comparing with expected fingerprint: $TEXLIVE_FPR"   && \
  if [ "${TEXLIVE_FPR}" != "${ACTUAL_FPR}" ]; then   \
    echo "ERROR: Fingerprint of proposed texlive key (${ACTUAL_FPR}) does not match expected fingerprint (${TEXLIVE_FPR})" >&2 ; \
    exit 1 ;   \
  fi  &&       \
  echo "DONE: Fingerprint matches expected value."

RUN                                                                                        \
  set -eux                                                                              && \
  # Dynamically obtain information on the architecture for which we re building
  #   Keep this in one RUN to have access to the dynamically created environment variables
  #   Another RUN opens up another shell  
  echo "*** Building for TARGETOS=${TARGETOS} TARGETARCH=${TARGETARCH} TARGETVARIANT=${TARGETVARIANT} TARGETPLATFORM=${TARGETPLATFORM}" && \
  \
  if [ "$TARGETOS" != "linux" ]; then                           \
    echo "ERROR: This dockerfile only supports TARGETOS=linux"; \
    exit 1;                                                     \
  fi;                                                           \
                                                                \
  case "${TARGETARCH}/${TARGETVARIANT}" in                      \
    amd64/* | amd64/"" )  TL_PLATFORM='x86_64-linux'  ;;        \
    386/* | 386/"" )      TL_PLATFORM='i386-linux'    ;;        \
    arm64/* | arm64/"" )  TL_PLATFORM='aarch64-linux' ;;        \
    arm/v7 )              TL_PLATFORM='armhf-linux'   ;;                  \
    arm/v6 ) echo "No supported TeX Live binaries for linux/arm/v6 (armel)"; exit 1 ;; \
    * )      echo "No matching TeX Live platform for ${TARGETOS}/${TARGETARCH}/${TARGETVARIANT}"; exit 1 ;; \
  esac;                                         \
  echo  "*** Using TL_PLATFORM=${TL_PLATFORM}" && \
                                                                                           \
  echo "*** Found TL_FILE_NAME=${TL_FILE_NAME}" && \
  echo "*** Found TL_YEAR=${TL_YEAR}" && \
  echo "*** Found TL_YEAR=${TL_ISO_URL}" && \
  echo "*** Downloading TeX Live ISO hash ${TL_ISO_URL}.sha512"                         && \
  curl -L "${TL_ISO_URL}.sha512" -o "/texlive/${TL_FILE_NAME}.sha512"                   && \
  echo "DONE: Downloaded TeX Live ISO hash ${TL_ISO_URL}.sha512"                        && \
                                                                                           \
  echo "*** File contents of /texlive/${TL_FILE_NAME}.sha512 is as follows: "           && \
  cat "/texlive/${TL_FILE_NAME}.sha512"                                                 && \
                                                                                           \
  echo "*** Downloading TeX Live ISO hash signataure ${TL_ISO_URL}.sha512.asc"          && \
  curl -L "${TL_ISO_URL}.sha512.asc" -o "/texlive/${TL_FILE_NAME}.sha512.asc"           && \
                                                                                           \
  echo "*** Verifying signature on the hash value "                                     && \
  gpg --verify "/texlive/${TL_FILE_NAME}.sha512.asc" "/texlive/${TL_FILE_NAME}.sha512"  && \
  echo "DONE: Verified signature on hash value"                                         && \
                                                                                           \
  ls -l /texlive                                                                        && \
  echo "*** Verifying hash value "                                                      && \
  # ensure proper path for sha512sum
  cd /texlive                                                                           && \
  sha512sum -c "${TL_FILE_NAME}.sha512"                                                 && \
  echo "DONE: Verified hash value "                                                     && \                                                                                                                                                                                                            
                                                                                           \                                                        
  echo "*** Extracting from ISO "                                                       && \
  mkdir -p /tmp/install-tl                                                              && \
  bsdtar -xf "/texlive/${TL_FILE_NAME}" -C /tmp/install-tl                              && \
  # remove ISO as soon as possible so as not to use up space on the device
  rm "/texlive/${TL_FILE_NAME}"                                                         && \
  echo "DONE: Extracted from ISO"                                                       && \
                                                                                           \
  echo "*** Creating TeX Live install profile"                                          && \
  echo "selected_scheme scheme-full" > /tmp/install-tl/install.profile                  && \
  # Reduce disk usage: do NOT install docs or source trees
  echo "tlpdbopt_install_docfiles 0" >> /tmp/install-tl/install.profile                 && \
  echo "tlpdbopt_install_srcfiles 0" >> /tmp/install-tl/install.profile                 && \
  # Disable automatic backups (common practice in container images)
  echo "tlpdbopt_autobackup 0" >> /tmp/install-tl/install.profile                       && \
  # Put TeX Live into a standard prefix that matches TL_YEAR
  echo "TEXDIR /usr/local/texlive/${TL_YEAR}" >> /tmp/install-tl/install.profile        && \
  # Request system-wide symlinks under /usr/bin (as in your snippet).
  # These will be re-created in the final stage via 'tlmgr path add'.
  echo "tlpdbopt_sys_bin /usr/bin" >> /tmp/install-tl/install.profile                   && \
  echo "DONE: Creating install profile "                                                && \
                                                                                           \
  echo "*** Installing TeX Live (non-interactive, profile-driven)"                      && \
  /tmp/install-tl/install-tl -profile /tmp/install-tl/install.profile                   && \
  ls -l /usr                                                                            && \
  ls -l /usr/local                                                                      && \
  ls -l /usr/local/texlive                                                              && \
  echo "DONE: Installing TeX Live "                                                     && \
                                                                                           \
  echo "*** Writing file to transport important parameters to next level "              && \
#
  printf "export TL_YEAR=\"%s\"\n"       "$TL_YEAR"          >> /usr/local/texlive/texlive-environment.sh  && \
  printf "export TL_PLATFORM=\"%s\"\n"   "$TL_PLATFORM"      >> /usr/local/texlive/texlive-environment.sh  && \    
  printf "export PATH=\"/usr/local/texlive/%s/bin/%s:%s\""   "${TL_YEAR}"  "${TL_PLATFORM}" "${PATH}"    >> /usr/local/texlive/texlive-environment.sh  && \
  echo "*** Cleaning up some files"                                                     && \
  rm -rf /texlive /tmp/install-tl                                                       && \
  echo "DONE: Cleaning up some files"



# =============================
#  Stage 2: Final runtime image
# =============================
FROM debian:stable-20251117-slim as dante

# Copy only the installed TeX Live tree from the builder stage
COPY --from=texlive-ready /usr/local/texlive /usr/local/texlive

ARG MEDIAWIKI_VERSION=1.39.0
ARG MEDIAWIKI_TARBALL=mediawiki-$MEDIAWIKI_VERSION.tar.gz
ARG MEDIAWIKI_URL=https://releases.wikimedia.org/mediawiki/1.39/$MEDIAWIKI_TARBALL
ARG TARGET=/wiki-dir

ARG TOP_PATH=/var/www/html/wiki-dir

##
## ARGs provided by the build system
##
# These are automatically set by buildx for each platform
# We here pick them up to 
#   (1) set proper LABELs in the docker image
#   (2) set proper paths (TODO: MAYBE NOT NEEDED in PHP)
ARG TARGETOS
ARG TARGETARCH
ARG TARGETVARIANT
ARG TARGETPLATFORM
ARG SOURCE_BRANCH
ARG SOURCE_COMMIT
ARG SOURCE_TAG
ARG DOCKERFILE_PATH
ARG IMAGE_NAME

ENV DEBIAN_FRONTEND=noninteractive


RUN \
  set -eux                                                      && \ 
  apt-get update                                                && \
  apt-get install -y --no-install-recommends perl               && \
  apt-get install -y --no-install-recommends  ca-certificates   && \
  apt-get install -y --no-install-recommends  curl              && \
  # recreate required environment
  echo "*** Checking environment file "                                                && \
  ls -l /usr/local     && \
  chmod 755 /usr/local/texlive/texlive-environment.sh                                  && \
  # Dynamically obtain information on the architecture for which we re building.sh
  . /usr/local/texlive/texlive-environment.sh                                          && \
  # Recreate system-wide symlinks into /usr/bin in THIS final image.
  # This respects 'tlpdbopt_sys_bin /usr/bin' stored in the TL database.
  echo "*** Creating TeX Live symlinks under /usr/bin via tlmgr path add"              && \
  tlmgr option sys_bin /usr/bin                                                        && \
  tlmgr path add

##
## LABEL 
##
#  NOTE: Only use ONE LABEL command, as this keep sthe number of layers down
# 
LABEL maintainer="Clemens H. Cap"                                                      \
  copyright="(C) 2022-2025 Clemens H. Cap"                                             \
  description="Dockerfile for Dantewiki"                                               \
  dockerhub-url="https://hub.docker.com/repository/docker/clecap/dante-wiki/general"   \
  git-url="https://github.com/clecap/dante-wiki"                                       \
  vcs-url="https://github.com/clecap/dante-wiki"                                       \
  license="AGPL 3"                                                                     \
  targetos="${TARGETOS}"                                                               \
  targetarch="${TARGETARCH}"                                                           \
  targetvariant="${TARGETVARIANT}"                                                     \
  targetplatform="${TARGETPLATFORM}"                                                   \
  org.opencontainers.image.source-branch="$SOURCE_BRANCH"                              \
  org.opencontainers.image.revision="$SOURCE_COMMIT"                                   \
  org.opencontainers.image.version="$SOURCE_TAG"                                       \
  org.opencontainers.image.dockerfile-path="$DOCKERFILE_PATH"                          \
  org.opencontainers.image.name="$IMAGE_NAME"

##
## ENV section
##
#
#
ENV LANG=C.UTF-8      \
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
    # TODO: We add the 2025 path while we are migrating from 2024 to 2025 
    #       We need this currently since it looks like (?) tlmgr is in the 2025 path
    # PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/local/texlive/$YEAR/bin/x86_64-linux:/bin:/usr/local/texlive/2025/bin/x86_64-linux:/bin        \
    # We must run composer as root, suppress warning and error messages about this
    COMPOSER_ROOT_VERSION=${MEDIAWIKI_VERSION}


WORKDIR /tmp


### CAVE: Do not delete the package files at this moment in tine or later installation steps might be troubled
#      /var/cache/debconf/*-old \
#      /var/lib/apt/lists/* \
#      /var/lib/dpkg/*-old \
#      /var/lib/dpkg/info/* \

# independently of what we find as shell setting in the base, we enforce /bin/bash
# this is necessary for some of the commands we use
SHELL ["/bin/bash", "-o", "pipefail", "-c"]


# Stuff we may clean at the end of each layer
ARG CLEAN_DOCKER_LAYER="          \
      /usr/share/doc              \
      /usr/share/man              \
      /usr/share/locale/*         \
      /usr/share/info             \
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
    set -eux   && \
    echo "*** *** *** Ensure docker desktop tab opens with a bash allowing command line editing  "                         && \ 
    rm /bin/sh                                                                                                             && \
    ln -sf /bin/bash /bin/sh                                                                                               && \
    echo "*** *** *** Generate target directories for the COPY operation below "                                           && \
    apt-get install -y   --no-install-recommends adduser                                                                   && \
    useradd -m dante && echo "dante:password" | chpasswd && adduser dante sudo                                             && \
    chown -R dante:dante /home/dante                                                                                       && \
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
    # TODO:     graphviz mscgen plantuml needed for extension:diagrams
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
    echo "*** *** *** Configuring apache modules and environment "                                                         
 
 RUN \
    #   select intended operating mode for Apache
    # the php modules of apache depend on mpm_prefork and must be disabled first
    # since we do not know which exact php module variant is installed with this apache, remove it a bit more broadly
    # since a2dismod does not allow shell expansion, do it as follows:
    # 1. Find enabled PHP module files (*.load)
    ls -l /etc/apache2/mods-enabled  && \
    mods_files=$(find /etc/apache2/mods-enabled -maxdepth 1 -name 'php*.load' -printf '%f\n')  && \
    echo "Found module files: $mods_files"       && \
    # 2. Strip the .load ending to get actual module names
    mods=$(echo "$mods_files" | sed 's/\.load$//')  && \
    echo "Module names to disable: $mods"   && \
    # 3. Disable them (only if something was found)
    [ -n "$mods" ] && a2dismod $mods     && \
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
    apt-get install -y --no-install-recommends python3-venv                                                             && \
    python3 -m venv /opt/myenv                                                                                             && \
    source /opt/myenv/bin/activate                                                                                         && \
    /opt/myenv/bin/pip3 install --no-cache-dir pymupdf                                                                     && \
##    
## Install aws command line for doing backups and similar stuff
##
    # need wheel package for installing aws command line
    /opt/myenv/bin/pip3 install --no-cache-dir wheel                                                                       && \
    /opt/myenv/bin/pip3 install awscli --use-pep517                                                                        && \
    ################################################################################################################# /opt/myenv/bin/pip3 install pygments && \
    echo "*** Deactivating virtual python environment"                                                                          && \
    deactivate                                                                                                                   && \
    echo "*** Preventing autoupdates of the image"                                                                         && \
    rm -f /etc/cron.daily/apt-compat                                                                                       && \
    echo "*** injecting the correct shell for www-data to enable a su to www-data "                                        && \
    chsh -s "/bin/bash" "www-data"                                                                                         && \
    echo "*** Installing and configuring sudo "                                                                            && \
    apt-get install -y --no-install-recommends sudo                                                                        && \
    echo "www-data ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers                                                                 && \
    chown -R www-data:www-data /var/www                                                                                    && \
    echo "*** *** *** Final cleanup "                                                                                      && \
    apt-get purge -y php-dev                                                                                               && \
    apt-get autoremove -y                                                                                                  && \
    apt-get clean                                                                                                          && \
    rm -rf ${CLEAN_DOCKER_LAYER}


# We do not want to have to chown files, as this is a very time consuming operation when many files are involved
# Thus we switch to a different user for the following operations
USER www-data

RUN curl -o "/tmp/$MEDIAWIKI_TARBALL" "$MEDIAWIKI_URL"                                      && \
    mkdir -p "/var/www/html/${TARGET}"                                                      && \
    tar -xzf "/tmp/$MEDIAWIKI_TARBALL" -C "/var/www/html/${TARGET}" --strip-components=1    && \
    rm "/tmp/$MEDIAWIKI_TARBALL"                                                            && \
    rm -Rf "/var/www/html/${TARGET}/skins/Refreshed/.git"

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
    /home/dante/dantescript/install-extension-github.sh  "${TOP_PATH}"  https://github.com/kuenzign/WikiMarkdown                                        WikiMarkdown                 main       && \
    /home/dante/dantescript/install-extension-github.sh  "${TOP_PATH}"  https://github.com/wikimedia/mediawiki-extensions-MobileFrontend                MobileFrontend               REL1_39    && \
    /home/dante/dantescript/install-extension-github.sh  "${TOP_PATH}"  https://github.com/wikimedia/mediawiki-extensions-RandomSelection               RandomSelection              REL1_39    && \
    /home/dante/dantescript/install-extension-github.sh  "${TOP_PATH}"  https://github.com/wikimedia/mediawiki-extensions-LabeledSectionTransclusion    LabeledSectionTransclusion   REL1_39    && \
    /home/dante/dantescript/install-extension-github.sh  "${TOP_PATH}"  https://github.com/wikimedia/mediawiki-extensions-RevisionSlider                RevisionSlider               REL1_39    && \
    /home/dante/dantescript/install-extension-github.sh  "${TOP_PATH}"  https://github.com/wikimedia/mediawiki-extensions-NativeSvgHandler              NativeSvgHandler             REL1_39    && \
    /home/dante/dantescript/install-extension-github.sh  "${TOP_PATH}"  https://github.com/wikimedia/mediawiki-extensions-WikiCategoryTagCloud          WikiCategoryTagCloud         REL1_39    && \
#
#
#    /home/dante/dantescript/install-extension-github.sh  ${TOP_PATH}  https://github.com/samwilson/diagrams-extension                                 Diagrams                     master     && \
##  TODO: diagrams-extension master currently breaks claimed backwards compatibility with MW 1.39
#
    /home/dante/dantescript/install-extension-github.sh  "${TOP_PATH}"  https://github.com/wikimedia/mediawiki-extensions-ReplaceText                   ReplaceText                  REL1_39    && \
##    /home/dante/dantescript/install-extension-github.sh  "${TOP_PATH}"  https://github.com/ProfessionalWiki/Network                                     Network                      master     && \
## TODO: Network not compatible with 1.39 release
#
    /home/dante/dantescript/install-extension-github.sh  "${TOP_PATH}"  https://github.com/wikimedia/mediawiki-extensions-SubPageList3                 SubPageList3                  REL1_39    && \
##    /home/dante/dantescript/install-extension-github.sh  "${TOP_PATH}"  https://github.com/ProfessionalWiki/SubPageList                                SubPageList                   master     && \
#     SubPageList uses 
##    /home/dante/dantescript/install-extension-github.sh  "${TOP_PATH}"  https://github.com/wikimedia/mediawiki-extensions-SubpageNavigation            SubpageNavigation             REL1_41    && \
#     SubpageNavigation not fully working in my 1.39 release.
#  installExtensionGithub  https://github.com/labster/HideSection/                                         HideSection master
#  TODO STUFF
#  looks like this extension is broken
#  installExtensionGithub https://github.com/wikimedia/mediawiki-extensions-WikEdDiff WikEdDiff REL1_39
#  The following is broken currently in REL1_38 only, might be fine in higher releases
    /home/dante/dantescript/install-extension-github.sh  "${TOP_PATH}"  https://github.com/Universal-Omega/DynamicPageList3                             DynamicPageList3             REL1_39    && \
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
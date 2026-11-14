##
## Dante Wiki Dockerfile
##
#
#  We work in two stages.
#  Stage 1: Build a system containing the required flavor of TeX. It should not be changed often due to runtime.
#  Stage 2: Copy in TeX system from stage 1
#
#  NOTE 1:  Building TeX and copying it in can be cached better, is more robust and minimal
#           then building and deleting stuff
#  NOTE 2:  We install TeX not through the network installer but through the ISO image.
#           ISO image requires only one large file transfer instead of thousands of downloads (slow)
#           ISO image is more robust (only one network call may fail instead of many over a long period of time)
#           ISO image can be pulled fast, especially when building at dockerhub

#  NOTE: ARGs do NOT carry over automagically to later stages but may be defined in global scope and then taken in 
#  NOTE: ARGs cannot be combined to reduce the number of layers
#
#  TL_YEAR: TeX Live year (used in paths and ISO name)
#  TEXLIVE_FPR: Expected fingerprint of the GPG public signing key
#                Key will be downloaded and checked against this fingerprint
#                So this amounts to some form of key pinning as well

# Versions of TeXLive
ARG TL_YEAR=2026
ARG TEXLIVE_FPR=C78B82D8C79512F79CC0D7C80D5E5D9106BAB6BC

# Versions of Mediawiki:  MAJO.MINOR.PATCH
ARG MEDIAWIKI_MAJOR=1
ARG MEDIAWIKI_MINOR=43
ARG MEDIAWIKI_PATCH=11

# Versions for picking up the typical extension version from its github distribution
ARG MEDIAWIKI_EXTENSION_TAG=REL1_43

# ==========================
#  Stage 1: TeX Live builder
# ==========================
FROM debian:stable-20261027-slim@sha256:13e0a2e78aa0554ad5ff66e4e260c6dbcdff807eb1f39d43b9fb0288aae88b04 AS texlive-ready

##
## Take in parameters defined in global scope
##

ARG TL_YEAR
ARG TEXLIVE_FPR

# We should derive subsequent argument values from here in ARG, since ENV values can be used only
# after the entire ENV command has been executed.
ARG  TL_FILE_NAME="texlive${TL_YEAR}.iso" 
# Fixed mirror instead of mirror.ctan.org: the redirector picks a random mirror per request, which sometimes
# has a broken TLS certificate, and ISO, .sha512 and .sha512.asc could come from mirrors at different states.
# Safe, since the ISO is verified against the GPG-signed sha512 hash below.
ARG  TL_ISO_URL="https://ftp.rrze.uni-erlangen.de/ctan/systems/texlive/Images/${TL_FILE_NAME}"

ENV  DEBIAN_FRONTEND=noninteractive   

# NOTE: set -eux; makes build more reliable
#           -e    exit on error, prevent silent failures
#           -u    treat unset variables as error; catches typos and missing variables
#           -x    print each command into the log before executing it
# NOTE: Each run starts a fresh shell, so need this at the beginning of every RUN

##
## ENV Section
##
#   Use only one ENV command, as this reduces the number of layers
ENV \
  # URL of the TeX Live signing key (ISO + hash URLs: see TL_ISO_URL above)
  # URL of the GPG key (silence hadolint, since this is a public key)
  # hadolint ignore=SC2154
  GPG_PUBKEY_URL="https://www.tug.org/texlive/files/texlive.asc" \
  TEXLIVE_PUBKEY_ID="TeX Live Distribution <tex-live@tug.org>" 

##
## ARGs provided by the build system
##
# These are automatically set by buildx for each platform
ARG TARGETOS
ARG TARGETARCH
ARG TARGETVARIANT
ARG TARGETPLATFORM

# pin shell to a bash and sensure that we do a pipefail
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Install required tools and do some small minimal cleanup
# - downloading (curl)
# - signature verification (gnupg, ca-certificates)
# - installer runtime (perl, xz-utils for compressed archives)
# - extracting ISO (libarchive-tools -> bsdtar)
 
RUN                                                                               \ 
  set -eux                                                                     && \
  apt-get update                                                               && \
  apt-get install -y --no-install-recommends ca-certificates=20250419+deb13u1  && \
  apt-get install -y --no-install-recommends curl=8.14.1-2+deb13u7             && \
  apt-get install -y --no-install-recommends gnupg=2.4.7-21+deb13u1            && \
  apt-get install -y --no-install-recommends perl=5.40.1-6+deb13u1             && \
  apt-get install -y --no-install-recommends xz-utils=5.8.1-1+deb13u2          && \
  apt-get install -y --no-install-recommends libarchive-tools=3.7.4-4+deb13u1  && \
  rm -rf /var/lib/apt/lists/*                                                  && \
                                                                                  \ 
  echo "*** Downloading TeXlive GPG key from ${GPG_PUBKEY_URL}"                && \
  curl -fsSL --retry 5 --retry-delay 10 --retry-all-errors "${GPG_PUBKEY_URL}" -o /tmp/key.asc  && \
  echo "DONE: Downloading TeXlive GPG key  from ${GPG_PUBKEY_URL}"             && \
                                                                                  \
  echo "*** Importing GPG key"                                                 && \
  gpg --batch --import /tmp/key.asc                                            && \
  echo "DONE: Importing the GPG key into the keyring"                          && \
                                                                                  \
  echo "*** Listing all keyring keys "                                         && \
  gpg --list-keys --fingerprint                                                && \
  echo "*** Listing the key we need"                                           && \
  gpg --list-keys "${TEXLIVE_PUBKEY_ID}"                                       && \
                                                                                  \
  echo "*** Obtaining the current fingerprint "                                && \
  ACTUAL_FPR="$(gpg --batch --with-colons --fingerprint "${TEXLIVE_PUBKEY_ID}" | awk -F: '/^fpr:/ {print $10; exit}')"  && \
  echo "DONE: Obtained current fingerprint:   $ACTUAL_FPR"                     && \
                                                                                  \
  echo "*** Comparing with expected fingerprint: $TEXLIVE_FPR"                 && \
  if [ "${TEXLIVE_FPR}" != "${ACTUAL_FPR}" ]; then   \
    echo "ERROR: Fingerprint of proposed texlive key (${ACTUAL_FPR}) does not match expected fingerprint (${TEXLIVE_FPR})" >&2 ; \
    exit 1 ;   \
  fi  &&       \
  echo "DONE: Fingerprint matches expected value."

# The TeX Live ISO (about 6 GB) is kept in a BuildKit cache mount: a directory of the local builder which survives
# from build to build (also --no-cache builds) and is shared by all platforms, but never ends up in the image.
# The ISO is downloaded only if the cached file does not match the GPG-signed sha512 hash, i.e. if it is missing,
# damaged, from another TeX Live year or reissued upstream.
#
#   sharing=locked: parallel builds (amd64 + arm64) wait for each other, so the ISO is downloaded only once
#
#   Clear the cache with: docker builder prune --filter type=exec.cachemount
#
RUN --mount=type=cache,id=texlive-iso,target=/cache,sharing=locked                        \
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
  echo "*** Found TL_ISO_URL=${TL_ISO_URL}" && \
  # work in the cache directory; sha512sum -c expects the ISO in the current directory
  cd /cache                                                                             && \
  echo "*** Downloading TeX Live ISO hash ${TL_ISO_URL}.sha512"                         && \
  curl -fL --retry 5 --retry-delay 10 --retry-all-errors "${TL_ISO_URL}.sha512" -o "${TL_FILE_NAME}.sha512"  && \
  echo "DONE: Downloaded TeX Live ISO hash ${TL_ISO_URL}.sha512"                        && \
                                                                                           \
  echo "*** File contents of /cache/${TL_FILE_NAME}.sha512 is as follows: "             && \
  cat "${TL_FILE_NAME}.sha512"                                                          && \
                                                                                           \
  echo "*** Downloading TeX Live ISO hash signataure ${TL_ISO_URL}.sha512.asc"          && \
  curl -fL --retry 5 --retry-delay 10 --retry-all-errors "${TL_ISO_URL}.sha512.asc" -o "${TL_FILE_NAME}.sha512.asc"  && \
                                                                                           \
  echo "*** Verifying signature on the hash value "                                     && \
  gpg --verify "${TL_FILE_NAME}.sha512.asc" "${TL_FILE_NAME}.sha512"                    && \
  echo "DONE: Verified signature on hash value"                                         && \
                                                                                           \
  echo "*** Checking for a cached ISO matching the hash value "                         && \
  if sha512sum -c "${TL_FILE_NAME}.sha512"; then                                           \
    echo "DONE: Using cached ISO /cache/${TL_FILE_NAME}";                                  \
  else                                                                                     \
    echo "*** No matching cached ISO, downloading TeX Live ${TL_ISO_URL}";                 \
    # download to a temporary name, so an interrupted download never looks like a complete ISO
    curl -fL --retry 5 --retry-delay 10 --retry-all-errors "${TL_ISO_URL}" -o "${TL_FILE_NAME}.part"; \
    mv "${TL_FILE_NAME}.part" "${TL_FILE_NAME}";                                           \
    echo "*** Verifying hash value of the downloaded ISO";                                 \
    sha512sum -c "${TL_FILE_NAME}.sha512";                                                 \
    echo "DONE: Downloaded and verified TeX Live ISO";                                     \
  fi                                                                                    && \
  # remove files of other TeX Live years, which would otherwise pile up in the cache
  find /cache -maxdepth 1 -type f ! -name "${TL_FILE_NAME}*" -print -delete             && \
  ls -l /cache                                                                          && \
                                                                                           \
  echo "*** Extracting from ISO "                                                       && \
  mkdir -p /tmp/install-tl                                                              && \
  bsdtar -xf "/cache/${TL_FILE_NAME}" -C /tmp/install-tl                                && \
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
  # tlcockpit is a GUI for tlmgr (Java, needs a display): useless in a container. The profile can only
  # exclude whole collections, and its collection-binextra is needed, so remove the single package here.
  # --force: collection-binextra depends on tlcockpit, tlmgr would otherwise refuse
  # We also remove it due to CVE-2020-9546 in maven / com.fasterxml.jackson.core/jackson-databind / 2.9.4
  # which is pulled in as dependency in tlcockpit
  /usr/local/texlive/${TL_YEAR}/bin/${TL_PLATFORM}/tlmgr remove --force tlcockpit       && \
  echo "*** Writing file to transport important parameters to next level "              && \
  printf "export TL_YEAR=\"%s\"\n"       "$TL_YEAR"          >> /usr/local/texlive/texlive-environment.sh  && \
  printf "export TL_PLATFORM=\"%s\"\n"   "$TL_PLATFORM"      >> /usr/local/texlive/texlive-environment.sh  && \    
  printf "export PATH=\"/usr/local/texlive/%s/bin/%s:%s\""   "${TL_YEAR}"  "${TL_PLATFORM}" "${PATH}"    >> /usr/local/texlive/texlive-environment.sh  && \
  echo "*** Cleaning up some files"                                                     && \
  rm -rf /tmp/install-tl                                                                && \
  echo "DONE: Cleaning up some files"



# =============================
#  Stage 2: Final runtime image
# =============================
FROM debian:stable-20261027-slim@sha256:13e0a2e78aa0554ad5ff66e4e260c6dbcdff807eb1f39d43b9fb0288aae88b04 AS dante

# Copy only the installed TeX Live tree from the builder stage
COPY --from=texlive-ready /usr/local/texlive /usr/local/texlive

##
## Take in parameters defined in global scope
##
ARG TL_YEAR
ARG MEDIAWIKI_MAJOR
ARG MEDIAWIKI_MINOR
ARG MEDIAWIKI_PATCH
ARG MEDIAWIKI_EXTENSION_TAG

ARG MEDIAWIKI_TARBALL=mediawiki-$MEDIAWIKI_MAJOR.$MEDIAWIKI_MINOR.$MEDIAWIKI_PATCH.tar.gz

ARG MEDIAWIKI_URL=https://releases.wikimedia.org/mediawiki/$MEDIAWIKI_MAJOR.$MEDIAWIKI_MINOR/$MEDIAWIKI_TARBALL

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

ENV DEBIAN_FRONTEND=noninteractive


RUN \
  set -eux                                                      && \ 
  apt-get update                                                && \
  apt-get install -y --no-install-recommends perl=5.40.1-6+deb13u1      && \
  apt-get install -y --no-install-recommends ca-certificates=20250419+deb13u1 && \
  apt-get install -y --no-install-recommends curl=8.14.1-2+deb13u7     && \
  # recreate required environment
  echo "*** Checking environment file "                                                && \
  ls -l /usr/local     && \
  chmod 755 /usr/local/texlive/texlive-environment.sh                                  && \
  # Dynamically obtain information on the architecture for which we re building.sh
  . /usr/local/texlive/texlive-environment.sh                                          && \
  # Recreate system-wide symlinks into /usr/bin in THIS final image.
  # This respects 'tlpdbopt_sys_bin /usr/bin' stored in the TL database.
  echo "*** Creating TeX Live symlinks under /usr/bin via tlmgr path add"              && \
  tlmgr path add                                                                       && \
  rm -rf /var/lib/apt/lists/* 
##
## LABEL 
##
#  NOTE: Only use ONE LABEL command, as this keep sthe number of layers down
# 
LABEL maintainer="Clemens H. Cap"                                                      \
  copyright="(C) 2022-2026 Clemens H. Cap"                                             \
  description="Dockerfile for Dantewiki"                                               \
  dockerhub-url="https://hub.docker.com/repository/docker/clecap/dante-wiki/general"   \
  git-url="https://github.com/clecap/dante-wiki"                                       \
  vcs-url="https://github.com/clecap/dante-wiki"                                       \
  license="AGPL 3"                                                                     \
  targetos="${TARGETOS}"                                                               \
  targetarch="${TARGETARCH}"                                                           \
  targetvariant="${TARGETVARIANT}"                                                     \
  targetplatform="${TARGETPLATFORM}"                                                   
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
    TEXDIR=/usr/local/texlive/$TL_YEAR  \
    # director for site-wide local files
    TEXMFLOCAL=/usr/local/texlive/texmf-local  \
    # directory for variable and automatically generated data
    TEXMFSYSVAR=/usr/local/texlive/$TL_YEAR/texmf-var  \
    # directory for local configuration
    TEXMFSYSCONFIG=/usr/local/texlive/$TL_YEAR/texmf-config \
    # personal directory for variable and automatically generated data
    TEXMFVAR=/var/www/.texlive$TL_YEAR/texmf-var         \           
    # personal directory for local config
    TEXMFCONFIG=/var/www/.texlive$TL_YEAR/texmf-config   \
    # directory for user specific files
    TEXMFHOME=/var/www/texmf       \
    # TEXINPUTS might be amended outside of the container as part of Parsifal etc.
    TEXINPUTS=/var/www/texinputs   

  ###### TODO: this might be deprecated
    # We must run composer as root, suppress warning and error messages about this
    ## COMPOSER_ROOT_VERSION=${MEDIAWIKI_VERSION}


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
      /var/cache/apt/*            \
      /var/cache/man/*            \
      /tmp/* "


## Install necessary packages
#   git                       get proper hashes in Special:Version and in other places
#   imagemagick               THUMBNAIL support in mediawiki
#   default-mysql-client      make dumps and restores via webserver interaction and via mediawiki special pages
#   msmtp                     write simple mails to inform about backup job completion and more
#   php-curl:                 must include this for the composer to run faster

# hadolint ignore=DL4005
RUN \
    set -eux                                                                                                               && \
    apt-get update                                                                                                         && \
    echo "*** *** *** Ensure docker desktop tab opens with a bash allowing command line editing  "                         && \
    rm /bin/sh                                                                                                             && \
    ln -sf /bin/bash /bin/sh                                                                                               && \
    echo "*** *** *** Generate target directories for the COPY operation below "                                           && \
    apt-get install -y   --no-install-recommends adduser                                                                   && \
    useradd -m dante                                                                                                       && \
    chown -R dante:dante /home/dante                                                                                       && \
    echo "*** *** *** Installations "                                                                                      && \
    apt-get update                                                                                                         && \
    apt-get install -y   --no-install-recommends  apache2                                                                  && \
    apt-get install -y   --no-install-recommends  apache2-utils                                                            && \
    apt-get install -y   --no-install-recommends  openssl                                                                  && \
    apt-get install -y   --no-install-recommends  php                                                                      && \
    apt-get install -y   --no-install-recommends  php-common                                                               && \
    apt-get install -y   --no-install-recommends  php-mysqli                                                               && \
    apt-get install -y   --no-install-recommends  php-intl                                                                 && \
    apt-get install -y   --no-install-recommends  php-apcu                                                                 && \
    apt-get install -y   --no-install-recommends  php-mbstring                                                             && \ 
    apt-get install -y   --no-install-recommends  php-gd                                                                   && \
    apt-get install -y   --no-install-recommends  php-json                                                                 && \
    apt-get install -y   --no-install-recommends  php-xml                                                                  && \
    apt-get install -y   --no-install-recommends  php-bcmath                                                               && \
    apt-get install -y   --no-install-recommends  php-tokenizer                                                            && \
    apt-get install -y   --no-install-recommends  php-igbinary                                                             && \
    apt-get install -y   --no-install-recommends  php-opcache                                                              && \                
    apt-get install -y   --no-install-recommends  php-pear php-curl                                                        && \
    apt-get install -y   --no-install-recommends  php-fpm                                                                  && \
    # PHP2Shell (CVE-2026-109618, CVE-2026-109619) is fixed in PHP 8.4.27 (Debian 8.4.27-1~deb13u1).
    # Fail the build if an older, vulnerable PHP got installed (e.g. from a stale build cache).
    { php -r 'exit(version_compare(PHP_VERSION, "8.4.27", ">=") ? 0 : 1);'                                                   \
      || { echo "*** ERROR: PHP $(php -r 'echo PHP_VERSION;') is vulnerable to PHP2Shell, need >= 8.4.27"; exit 1; }; }   && \
    apt-get install -y   --no-install-recommends  default-mysql-client                                                     && \
    apt-get install -y   --no-install-recommends  curl                                                                     && \
    apt-get install -y   --no-install-recommends  unzip                                                                    && \
    apt-get install -y   --no-install-recommends  git                                                                      && \
    apt-get install -y   --no-install-recommends  diffutils                                                                && \
    apt-get install -y   --no-install-recommends  logrotate                                                                && \
    #   vim:        it is very convenient to have a vi editor in place for development inside of the container
    apt-get install -y   --no-install-recommends vim                                                                       && \
    #   configure git: prevent hints about the default branch master
    git config --global init.defaultBranch master                                                                          && \
    #
    #
    apt-get install -y   --no-install-recommends   imagemagick                                                             && \
    apt-get install -y   --no-install-recommends   netpbm                                                                  && \
    apt-get install -y   --no-install-recommends   djvulibre-bin                                                           && \
    apt-get install -y   --no-install-recommends   librsvg2-bin                                                            && \
    apt-get install -y   --no-install-recommends   xpdf                                                                    && \
    apt-get install -y   --no-install-recommends   gnuplot-nox                                                             && \
    # graphviz, mscgen, plantum required for: https://www.mediawiki.org/wiki/Extension:Diagrams
    apt-get install -y   --no-install-recommends   graphviz                                                                && \
    apt-get install -y   --no-install-recommends   mscgen                                                                  && \
    # PlantUML: NOT the Debian package "plantuml" (trixie ships the outdated 1.2020.2 from 2020).
    #   Instead: official jar from https://github.com/plantuml/plantuml/releases, pinned by version and sha256.
    #   To update: change version and sha256 (the sha256 is shown as "digest" of plantuml-<version>.jar on the release page).
    #   The Debian package used to pull in Java; we now install the JRE explicitly (graphviz is installed above).
    #   The wrapper /usr/local/bin/plantuml keeps the "plantuml" command available for the Diagrams extension.
    apt-get install -y   --no-install-recommends   default-jre-headless                                                    && \
    mkdir -p /opt/plantuml                                                                                                 && \
    curl -fsSL --retry 5 --retry-delay 10 --retry-all-errors -o /opt/plantuml/plantuml.jar \
      https://github.com/plantuml/plantuml/releases/download/v1.2026.10/plantuml-1.2026.10.jar                             && \
    echo "e9bc9e6b2eb715e8c0c929f3dcb5fc1923be13f37599b09c293c66d354e88686  /opt/plantuml/plantuml.jar" | sha256sum -c -  && \
    printf '#!/bin/sh\nexec java -Djava.awt.headless=true -jar /opt/plantuml/plantuml.jar "$@"\n' > /usr/local/bin/plantuml  && \
    chmod 755 /usr/local/bin/plantuml                                                                                      && \
    apt-get install -y   --no-install-recommends   msmtp                                                                   && \
    echo "*** *** *** Installing composer "                                                                                && \
    # Composer >= 2.9 blocks packages with security advisories; see the audit.ignore exception before "composer update" below
    curl -fsS --retry 5 --retry-delay 10 --retry-all-errors https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer --version=2.11.2  && \
    echo "*** *** *** Installing ds (needed for Parsifal cleanup code), which needs pecl, which needs php-dev and make "                                      && \
    apt-get install -y --no-install-recommends  php-dev  make                                                              && \
    pecl channel-update pecl.php.net                                                                                       && \
    pecl install ds                                                                                                        && \
    apt-get purge -y  php-dev  make                                                                                        && \
    echo "*** *** *** Install python and pip for supporting TeX (minted) and Parsifal "                                    && \
    apt-get install -y --no-install-recommends  python3                                                                    && \
    apt-get install -y --no-install-recommends  python3-pip                                                                && \    
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
    mods="${mods_files//.load/}"  && \
    echo "Module names to disable: $mods"   && \
    # 3. Disable them (only if something was found)
    [ -n "$mods" ] && echo "$mods" | xargs a2dismod  && \
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
# remove unwanted apache configuration files
    a2disconf charset.conf                                                                                                 && \
    a2disconf localized-error-pages.conf                                                                                   && \
    a2disconf security.conf                                                                                                && \
    a2disconf serve-cgi-bin.conf                                                                                           && \
#   ssh client and rsync needed for doing backups           
    apt-get install -y --no-install-recommends openssh-client                                                              && \
    apt-get install -y --no-install-recommends rsync                                                                       && \
## Install pymupdf
#
#    1) Installations with pip should use a virtual python environment or a --break-system-package (which is not recommended)
#    2) For some reason the active shell has no source command and we need to switch to bash
#    3) This also is an issue when the install triggers for python3.11-venv are activated
    echo "*** installing python stuff in virtual environment "                                                             && \
    apt-get install -y --no-install-recommends python3-venv                                                                && \
    python3 -m venv /opt/myenv                                                                                             && \
    source /opt/myenv/bin/activate                                                                                         && \
    /opt/myenv/bin/pip3 install --no-cache-dir pymupdf                                                                     && \
##    
## Install aws command line for doing backups and similar stuff
##
    # need wheel package for installing aws command line
    /opt/myenv/bin/pip3 install --no-cache-dir wheel                                                                       && \
    /opt/myenv/bin/pip3 install awscli --use-pep517                                                                        && \
    echo "*** Deactivating virtual python environment"                                                                          && \
    deactivate                                                                                                                   && \
    echo "*** Preventing autoupdates of the image"                                                                         && \
    rm -f /etc/cron.daily/apt-compat                                                                                       && \
    echo "*** injecting the correct shell for www-data to enable a su to www-data "                                        && \
    chsh -s "/bin/bash" "www-data"                                                                                         && \
#   The image runs as www-data, and the startup scripts (run-apache.sh, install-webserver-certificate.sh, ...)
#   need sudo for configuring and starting apache. TODO: restrict this to a single root-owned script.
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

RUN curl -fL --retry 5 --retry-delay 10 --retry-all-errors -o "/tmp/$MEDIAWIKI_TARBALL" "$MEDIAWIKI_URL"  && \
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
#   Composer dependencies of extensions: MediaWiki's composer.json merges composer.local.json (merge plugin).
#   The wildcard include below makes every "composer update" also merge extensions/*/composer.json, so the
#   dependencies of all extensions present at that moment end up in the shared vendor/ directory.
#   Example: DrawioEditor REL1_43 needs mwstake/* packages (its extension.json callback mwsInitComponents
#   is defined there); without this, every page dies with "callback 'mwsInitComponents' is not callable".
#   merge-dev=false: do not install the development tools (codesniffer, phpunit, ...) listed in require-dev.
#   NOTE: extensions added later (e.g. in the running container) need another "composer update" in ${TOP_PATH}.
    COMPOSER=${TOP_PATH}/composer.local.json  composer config --json extra.merge-plugin '{"include":["extensions/*/composer.json"],"merge-dev":false}'  && \
    composer config --global allow-plugins true                                                  && \
    echo "<?php " > ${TOP_PATH}/DanteDynamicInstalls.php                                         && \
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
    /home/dante/dantescript/install-extension-github.sh  "${TOP_PATH}"  https://github.com/wikimedia/mediawiki-extensions-MobileFrontend                MobileFrontend               ${MEDIAWIKI_EXTENSION_TAG}    && \
    /home/dante/dantescript/install-extension-github.sh  "${TOP_PATH}"  https://github.com/wikimedia/mediawiki-extensions-RandomSelection               RandomSelection              ${MEDIAWIKI_EXTENSION_TAG}    && \
    /home/dante/dantescript/install-extension-github.sh  "${TOP_PATH}"  https://github.com/wikimedia/mediawiki-extensions-LabeledSectionTransclusion    LabeledSectionTransclusion   ${MEDIAWIKI_EXTENSION_TAG}    && \
    /home/dante/dantescript/install-extension-github.sh  "${TOP_PATH}"  https://github.com/wikimedia/mediawiki-extensions-RevisionSlider                RevisionSlider               ${MEDIAWIKI_EXTENSION_TAG}    && \
    /home/dante/dantescript/install-extension-github.sh  "${TOP_PATH}"  https://github.com/wikimedia/mediawiki-extensions-NativeSvgHandler              NativeSvgHandler             ${MEDIAWIKI_EXTENSION_TAG}    && \
    /home/dante/dantescript/install-extension-github.sh  "${TOP_PATH}"  https://github.com/wikimedia/mediawiki-extensions-WikiCategoryTagCloud          WikiCategoryTagCloud         ${MEDIAWIKI_EXTENSION_TAG}    && \
#
#
  /home/dante/dantescript/install-extension-github.sh  "${TOP_PATH}"  https://github.com/ProfessionalWiki/NativeMarkdown          NativeMarkdown        master    && \
   ##
   ## Diagrams had a problem which I fixed in my own fork, but my pull request has not yet been honored by upstream.
   ## /home/dante/dantescript/install-extension-github.sh  "${TOP_PATH}"   https://github.com/samwilson/diagrams-extension                                 Diagrams                     master     && \
   /home/dante/dantescript/install-extension-github.sh  "${TOP_PATH}"   https://github.com/clecap/diagrams-extension                                 Diagrams                     mermaid-12  DEV     && \  
##  TODO: diagrams-extension master currently breaks claimed backwards compatibility with MW 1.39
#
    /home/dante/dantescript/install-extension-github.sh  "${TOP_PATH}"  https://github.com/wikimedia/mediawiki-extensions-ReplaceText                   ReplaceText                  ${MEDIAWIKI_EXTENSION_TAG}    && \
    /home/dante/dantescript/install-extension-github.sh  "${TOP_PATH}"  https://github.com/ProfessionalWiki/Network                                     Network                      master     && \
#
    /home/dante/dantescript/install-extension-github.sh  "${TOP_PATH}"  https://github.com/wikimedia/mediawiki-extensions-SubPageList3                 SubPageList3                  ${MEDIAWIKI_EXTENSION_TAG}    && \
##    /home/dante/dantescript/install-extension-github.sh  "${TOP_PATH}"  https://github.com/wikimedia/mediawiki-extensions-SubpageNavigation            SubpageNavigation             REL1_41    && \
#     SubpageNavigation not fully working in my 1.39 release.
#  installExtensionGithub  https://github.com/labster/HideSection/                                         HideSection master
#  TODO STUFF
#  looks like this extension is broken
#  installExtensionGithub https://github.com/wikimedia/mediawiki-extensions-WikEdDiff WikEdDiff REL1_39
   /home/dante/dantescript/install-extension-github.sh  "${TOP_PATH}"  https://github.com/Universal-Omega/DynamicPageList4                             DynamicPageList4             ${MEDIAWIKI_EXTENSION_TAG}    && \
    /home/dante/dantescript/install-extension-github.sh  "${TOP_PATH}"  https://github.com/clecap/parsifal          Parsifal         master   DEV && \
   /home/dante/dantescript/install-extension-github.sh  "${TOP_PATH}"  https://github.com/wikimedia/mediawiki-extensions-DrawioEditor         DrawioEditor         ${MEDIAWIKI_EXTENSION_TAG}    && \
##
  echo "*** Installing drawio external service into target=${TARGET}\n"     && \
  mkdir -p ${TOP_PATH}/external-services/draw-io/   && \
  git clone --depth 1 --branch dev --single-branch https://github.com/jgraph/drawio.git ${TOP_PATH}/external-services/draw-io/drawio-dev  && \
  rm -Rf ${TOP_PATH}/external-services/draw-io/drawio-dev/.git && \
#  Composer >= 2.9 refuses to install packages with known security advisories. MediaWiki 1.43 core pins
#  symfony/yaml to exactly 5.4.52 (core composer.json), which has two advisories (fixed in 5.4.54 / 5.4.56),
#  so without this exception "composer update" cannot resolve anything. The exception is limited to these two
#  advisories; any other advisory still blocks. Risk is low: MediaWiki parses only its own config/schema YAML
#  files with it, not user content. REMOVE this once a MediaWiki 1.43 point release raises the symfony/yaml pin.
   composer config --json audit.ignore '{"CVE-2026-109413": "symfony/yaml 5.4.52 pinned by MediaWiki 1.43 core", "GHSA-hwfg-qwvh-2wfx": "symfony/yaml 5.4.52 pinned by MediaWiki 1.43 core"}'  && \
   composer update


## 
## Adhere to default non-root user policy promoted by dockerhub
##
#  Create a non-root user and add to the sudo group
#  Set the home directory and working directory for the new user
#  Copy your application code to the container
#  Give non-root user ownership of the application files
#  Set the default user ## TODO: do we want this? is it compatible with the deletion strategies we need ???

##
## Default parameters for the entrypoint script below
##
CMD ["run-apache.sh"]

##
## Specify entrypoint, which will itself execute scripts provided as parameter
##
ENTRYPOINT ["/lap-entrypoint.sh"]
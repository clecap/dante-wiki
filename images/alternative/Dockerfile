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
FROM debian:stable-20251117-slim 

ENV DEBIAN_FRONTEND=noninteractive

# Copy only the installed TeX Live tree from the builder stage.
COPY --from=texlive-ready /usr/local/texlive /usr/local/texlive

# Install minimal runtime deps only.
# - perl: needed by tlmgr and many TL scripts
# - ca-certificates: useful if tlmgr ever talks to HTTPS mirrors
RUN \
  set -eux                                                      && \ 
  apt-get update                                                && \
  apt-get install -y --no-install-recommends perl               && \
  apt-get install -y --no-install-recommends  ca-certificates   && \
  rm -rf /var/lib/apt/lists/*                                   && \
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

# Default command: show the pdfTeX version to prove TL is working.
# CMD ["pdflatex", "--version"]


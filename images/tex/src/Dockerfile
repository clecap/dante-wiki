FROM clecap/ssh-copy

# We are starting with our own, small ssh on alpine image
# We are not starting with an image containing a larger configuration since 
# 1) this will be changed more frequently and
# 2) the TeX build takes quite some time.

LABEL "vendor"="Clemens H. Cap"
LABEL "maintainer"="clemens.cap@uni-rostock.de"

ENV LANG=C.UTF-8 \
  LC_ALL=C.UTF-8 \    
  # ConTeXt cache can be created on runtime and does not need to increase image size
  TEXLIVE_INSTALL_NO_CONTEXT_CACHE=1 \ 
  # As we will not install regular documentation why would we want to install perl docs…
  NOPERLDOC=1 \ 
  # The base mirror is one of the mirrors of TUG's historic archive
  TLHISTMIRRORURL=rsync://texlive.info/historic/systems/texlive \ 
  # To get the latest packages available we always use the root mirror
  TLMIRRORURL=http://dante.ctan.org/tex-archive/systems/texlive/tlnet

# Upgrade existing packages in the base image
RUN apk --no-cache update &&              \  
    apk --no-cache upgrade &&    \
    apk --no-cache add wget &&  \
    apk --no-cache add rsync && \
    apk --no-cache add unzip && \
    apk --no-cache add git &&   \
    apk --no-cache add gpg && \
    apk --no-cache add tar && \
    apk --no-cache add xorriso && \
    apk --no-cache add make && \
    apk --no-cache add fontconfig && \
    apk --no-cache add perl && \
    apk --no-cache add openjdk11-jre && \
    apk --no-cache add ncurses-libs && \
    apk --no-cache add perl-unicode-linebreak && \
    apk --no-cache add python3 && \
    apk --no-cache add py3-pygments && \
    apk --no-cache add curl &&  \
    # ghostscript
    apk --no-cache add ghostscript && \
    # gnuplot
    apk --no-cache add gnuplot && \
    # graphviz
    apk --no-cache add graphviz && \
    # fonts needed for graphviz
    apk add --update font-bitstream-type1 ghostscript-fonts ttf-cantarell && \
    # inkscape
    apk --no-cache add inkscape && \
    # mupdf
    apk --no-cache add mupdf && \
    # mupdf-tools
    apk --no-cache add mupdf-tools && \
    cd /tmp && \
    wget https://mirror.ctan.org/systems/texlive/tlnet/install-tl-unx.tar.gz && \
    zcat install-tl-unx.tar.gz | tar xf - && \
    cd install-tl-* && \
    # select full installation
    echo "selected_scheme scheme-full" > install.profile && \
    # do not install doc files
    echo "tlpdbopt_install_docfiles 0" >> install.profile && \
    # do not install src files
    echo "tlpdbopt_install_srcfiles 0" >> install.profile && \
    # do not know what this does but everybody does so (shitty approach, I know)
    echo "tlpdbopt_autobackup 0" >> install.profile && \
    # furthermore we want our symlinks in the system binary folder to avoid
    echo "tlpdbopt_sys_bin /usr/bin" >> install.profile && \
    # actually install TeX Live
    ./install-tl -profile install.profile  && \
    # cleanup
    cd /tmp && \
    rm -Rf /tmp/* && \
    rm -Rf /var/cache/apk/*

# There is already an entrypoint in the base image ssh
# ENTRYPOINT ["/bin/sh","-c","sleep infinity"]
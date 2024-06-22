FROM debian:stable-slim

## Variable CTAN designates the site where to obtain texlive from.
#  We mmight want to set it to a different value when there is a problem with a site assigned by mirror.ctan.org
#  CTAN could be mirror.ctan.org
#  CTAN could also designate a specific mirror, such as ctan.net


ARG CTAN=ctan.net
ARG YEAR=2024

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
    PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/local/texlive/$YEAR/bin/x86_64-linux:/bin:

WORKDIR /tmp


#### TODO: do we really need ghostscript libx11-dev   libxaw-dev   ???

RUN apt-get update && \ 
    apt-get install -y   --no-install-recommends  wget perl gnupg ghostscript libx11-dev libxaw7-dev ca-certificates && \
    echo "*** *** *** Now installing Texlive "                                                             && \
    wget --progress=dot:giga https://$CTAN/systems/texlive/tlnet/install-tl-unx.tar.gz                && \
    wget --progress=dot:giga https://$CTAN/systems/texlive/tlnet/install-tl-unx.tar.gz.sha512         && \
    wget --progress=dot:giga https://$CTAN/systems/texlive/tlnet/install-tl-unx.tar.gz.sha512.asc     && \
    echo "*** *** *** downloading GPG key "                                                                && \
    wget --progress=dot:giga https://www.tug.org/texlive/files/texlive.asc                            && \
    echo "*** *** *** importing GPG key "                                                                  && \
    gpg --import /tmp/texlive.asc && \
    echo "*** *** *** Verifying signature on Texlive installer "  && \
    gpg --verify /tmp/install-tl-unx.tar.gz.sha512.asc /tmp/install-tl-unx.tar.gz.sha512 && \
    echo "*** *** *** Verifying hash value "  && \
    sha512sum -c /tmp/install-tl-unx.tar.gz.sha512 && \
    zcat install-tl-unx.tar.gz | tar xf - && \
    cd install-tl-* && \
    # select full installation
    echo "*** *** *** Adjusting install profile "  && \
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
##
##  Adjust for present vulnerabilities
##
    # tlcockpit contains packages where docker reports severe security issues - and we do not need it since it is a GUI tool
    # since i did not really manage to exclude it in the installation - I here remove it the brutal way
#    rm -rf /usr/local/texlive/2024/texmf-dist/scripts/tlcockpit && \
#    rm -rf /usr/local/texlive/2024/bin/x86_64-linux/tlcockpit && \
#    rm -rf /usr/local/texlive/2024/texmf-dist/scripts/texplate && \
#    rm -rf /usr/local/texlive/2024/texmf-dist/scripts/arara  && \
#    rm -rf /usr/local/texlive/2024/texmf-dist/scripts/latex2nemeth && \
# 
#  tlcockpit removal without --force is refused, so add it here
#  need to update the database 
#
    tlmgr remove --force tlcockpit  && \
    tlmgr remove --force texplate   && \
    tlmrg remove --force arara      && \
    tlmgr remove --force latex2nemeth      && \
    tlmgr update --self && \
    tlmgr update --all && \
##
##
    echo "*** *** *** Verify Version "  && \
    tlmgr --version && \
##
##  Now cleanup
##
    echo "*** *** *** Doing a layer cleanup "  && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /usr/share/doc \
      /usr/share/man \
      /usr/share/locale/* \
      /usr/share/info \
      /var/cache/apt/* \
      /var/cache/man/* \
      /tmp/*

### Do not delete the package files or later installation steps might be troubled
#      /var/cache/debconf/*-old \
#      /var/lib/apt/lists/* \
#      /var/lib/dpkg/*-old \
#      /var/lib/dpkg/info/* \

ENTRYPOINT ["/bin/sh","-c","sleep infinity"]

# Set the default command
CMD ["bash"]

#
# Use fixed version number in the interest of reporducible builds
#
FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \    
    # ConTeXt cache can be created on runtime and does not need to increase image size  
    TEXLIVE_INSTALL_NO_CONTEXT_CACHE=1 \ 
    # As we will not install regular documentation why would we want to install perl docs…
    NOPERLDOC=1 \ 
    # The base mirror is one of the mirrors of TUG's historic archive
    TLHISTMIRRORURL=rsync://texlive.info/historic/systems/texlive \ 
    # To get the latest packages available we always use the root mirror
    TLMIRRORURL=http://dante.ctan.org/tex-archive/systems/texlive/tlnet \
    # 
    # the following environment variables are needed for TeX operations, for PARSIFAL and DANTEWIKI
    # 
    # main TeX directory
    TEXDIR=/usr/local/texlive/2024  \
    # director for site-wide local files
    TEXMFLOCAL=/usr/local/texlive/texmf-local  \
    # directory for variable and automatically generated data
    TEXMFSYSVAR=/usr/local/texlive/2024/texmf-var  \
    # directory for local configuration
    TEXMFSYSCONFIG=/usr/local/texlive/2024/texmf-config \
    # personal directory for variable and automatically generated data
    TEXMFVAR=/var/www/.texlive2024/texmf-var         \           
    # personal directory for local config
    TEXMFCONFIG=/var/www/.texlive2024/texmf-config   \
    # directory for user specific files
    TEXMFHOME=/var/www/texmf       \
    # TEXINPUTS might be amended outside of the container as part of Parsifal etc.
    TEXINPUTS=/var/www/texinputs   \
    #  We are setting the path so that we can more easily exercise and test commands inside of a docker exec shell
    PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/local/texlive/2024/bin/x86_64-linuxmusl:/bin:

# Upgrade existing packages in the base image 

RUN apt-get update && \
    apt-get install -y   --no-install-recommends\
      wget perl ghostscript libx11-dev libxaw7-dev ca-certificates && \
    echo "*** *** *** Now installing Texlive "         && \
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
    # exclude some packages which we do not want to install
    # tlcockpit, since it contains many security vulnerabilities and only provides an interactive UI which we do not need
    echo "tlpdbopt_exclude tlcockpit" >> install.profile  && \
    # actually install TeX Live
    ./install-tl -profile install.profile  && \
    echo "*** *** *** Now doing a layer cleanup "  && \
#    apk del wget curl rsync git gpg tar python3-dev build-base linux-headers    && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /usr/share/doc \
      /usr/share/man \
      /usr/share/locale/* \
      /usr/share/info \
      /var/cache/apt/* \
      /var/cache/man/* \
      /tmp/*

#      /var/cache/debconf/*-old \
#      /var/lib/apt/lists/* \
#      /var/lib/dpkg/*-old \
#      /var/lib/dpkg/info/* \



ENTRYPOINT ["/bin/sh","-c","sleep infinity"]




#curl                     &&    \
# rsync                    &&   \
# unzip                    &&   \
# git                      &&   \
# gpg                      &&   \
# tar                      && \
# xorriso                  && \
#fontconfig               && \
# perl                     && \
# openjdk11-jre            && \
# ncurses-libs             && \
# perl-unicode-linebreak   && \
# build-base                      && \
#linux-headers                   && \
# python3                         && \
#    ln -sf python3 /usr/bin/python                     &&\
# python3-dev                     && \
# py3-pip                         && \
#    pip3 install --no-cache --upgrade pip setuptools --break-system-packages   &&\
#    pip3 install python-config --break-system-packages                        &&\
#    pip3 install pymupdf --break-system-packages                              &&\
#    echo "*** *** *** DONE building pymupdf "          && \
   # no longer need mupdf as we use pymupdf 
    ### apk --no-cache add mupdf && \
    ### apk --no-cache add mupdf-tools && \
#    apk --no-cache add py3-pygments                    && \
#    apt-get install -y --no-install-recommends ghostscript                     && \
#    gnuplot                         && \
#    inkscape                        && \
#     plantuml                        && \
#     graphviz                        && \
    # fonts needed for graphviz
#    apk add --update font-bitstream-type1 ghostscript-fonts ttf-cantarell && \
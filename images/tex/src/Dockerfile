#
# Use fixed version number in the interest of reporducible builds
#
FROM alpine:3.18.4

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
    TEXDIR=/usr/local/texlive/2023  \
    # director for site-wide local files
    TEXMFLOCAL=/usr/local/texlive/texmf-local  \
    # directory for variable and automatically generated data
    TEXMFSYSVAR=/usr/local/texlive/2023/texmf-var  \
    # directory for local configuration
    TEXMFSYSCONFIG=/usr/local/texlive/2023/texmf-config \
    # personal directory for variable and automatically generated data
    TEXMFVAR=/var/www/.texlive2023/texmf-var         \           
    # personal directory for local config
    TEXMFCONFIG=/var/www/.texlive2023/texmf-config   \
    # directory for user specific files
    TEXMFHOME=/var/www/texmf       \
    # TEXINPUTS might be amended outside of the container as part of Parsifal etc.
    TEXINPUTS=/var/www/texinputs   \
    #  We are setting the path so that we can more easily exercise and test commands inside of a docker exec shell
    PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/local/texlive/2024/bin/x86_64-linuxmusl:/usr/local/texlive/2023/bin/x86_64-linuxmusl:/bin:/usr/local/texlive/2022/bin/x86_64-linuxmusl

# Upgrade existing packages in the base image
RUN apk --no-cache update             &&    \  
    apk --no-cache upgrade            &&    \
    apk --no-cache add wget           &&    \
    apk --no-cache add curl           &&    \
    apk --no-cache add rsync          &&   \
    apk --no-cache add unzip          &&   \
    apk --no-cache add git            &&   \
    apk --no-cache add gpg            &&   \
    apk --no-cache add tar            && \
    apk --no-cache add xorriso        && \
    apk --no-cache add fontconfig     && \
    apk --no-cache add perl           && \
    apk --no-cache add openjdk11-jre  && \
    apk --no-cache add ncurses-libs && \
    apk --no-cache add perl-unicode-linebreak && \
    apk --no-cache add python3 && \
    apk --no-cache add python3-dev &&\
#   Needed for mupdf python tooling 
    apk --no-cache add build-base      && \
    apk --no-cache add linux-headers  && \
    ln -sf python3 /usr/bin/python  &&\
    python3 -m ensurepip &&\
    pip3 install --no-cache --upgrade pip setuptools &&\
    pip3 install python-config &&\
#    cd /usr/lib/python3.9/config-3.9-x86_64-linux-musl &&\
    pip3 install pymupdf &&\
    apk --no-cache add py3-pygments && \
    apk --no-cache add ghostscript && \
    apk --no-cache add gnuplot && \
    apk --no-cache add graphviz && \
    # fonts needed for graphviz
    apk add --update font-bitstream-type1 ghostscript-fonts ttf-cantarell && \
    apk --no-cache add inkscape && \
    apk --no-cache add mupdf && \
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
    ###
    apk del python3-dev, rsync, gpg, tar, make    && \
    cd /tmp && \
    rm -Rf /tmp/* && \
    rm -Rf /var/cache/apk/*


ENTRYPOINT ["/bin/sh","-c","sleep infinity"]
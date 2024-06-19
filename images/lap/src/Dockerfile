FROM tex

WORKDIR /tmp

# independently of what we find as shell setting in the base, we enforce /bin/bash
# this is necessary for some of the commands we use
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

######################### DO WE REALLY NEED mupdf and mupdf-tools ?????????????????????????????????????????

# Install necessary packages
#   git          get proper hashes in Special:Version and in other places
#   imagemagick  THUMBNAIL support in mediawiki
#   DEFAULT-mysql-client      make dumps and restores via webserver interaction and via mediawiki special pages
#   msmtp             write simple mails to inform about backup job completion and more

RUN apt-get update && \
    apt-get install -y   --no-install-recommends apache2 ca-certificates apache2-utils openssl && \
    apt-get install -y   --no-install-recommends php && \
    apt-get install -y   --no-install-recommends php-common php-mysqli php-intl php-apcu php-mbstring php- php-gd php-json php-xml php-bcmath php-tokenizer php-igbinary php-opcache php-pear && \
    apt-get install -y   --no-install-recommends libapache2-mod-php default-mysql-client && \
    apt-get install -y   --no-install-recommends wget curl unzip git diffutils  && \
    apt-get install -y   --no-install-recommends imagemagick netpbm djvulibre-bin librsvg2-bin xpdf mscgen msmtp gnuplot-nox graphviz && \
    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer && \
    apt-get install -y --no-install-recommends php-dev make && \
    pecl channel-update pecl.php.net && \
    pecl install ds && \
##
## Get python and pip and then PYMUPDF and PYGMENTS for supporting TeX and Parsifal
##
    apt-get install -y --no-install-recommends mupdf mupdf-tools python3 python3-pip && \
    ln -sf python3 /usr/bin/python && \
    apt-get install -y --no-install-recommends python3-setuptools 

#
## Install pymupdf
#
#  This is a bit tricky, since
#    1) Installations with pip should use a virtual python environment or a --break-system-package (which is not recommended)
#    2) For some reason the active shell has no source command and we need to switch to bash
#    3) This also is an issue when the install triggers for python3.11-venv are activated


#RUN /bin/bash -c "apt-get install -y --no-install-recommends python3.11-venv"  && \
#    cd /opt && \
#    python3 -m venv myenv && \
#    /bin/bash -c "source myenv/bin/activate" && \

RUN apt-get install -y --no-install-recommends python3.11-venv  && \
    cd /opt && \
    python3 -m venv myenv && \
    source myenv/bin/activate && \
    /opt/myenv/bin/pip3 install --no-cache-dir pymupdf && \
    exit && \
##
## AMAZON CLOUD COMMAND LINE (for backup)
##
    cd /tmp && \
    curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install && \
    rm -rf awscliv2.zip aws && \
##
## FINAL CLEANUP
##
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

##
## COPY in docker context
##
COPY . /

## 
## Adhere to default non-root user policy promoted by dockerhub
##
#  Create a non-root user and add to the sudo group
#  Set the home directory and working directory for the new user
#  Copy your application code to the container
#  Give non-root user ownership of the application files
#  Set the default user

RUN useradd -m dante && echo "dante:password" | chpasswd && adduser dante sudo
    WORKDIR /home/dante
    RUN chown -R dante:dante /home/dante
    USER dante







##
## Default parameters for the entrypoint script below
##
CMD ["run-apache.sh"]

##
## Specify entrypoint, which will itself execute scripts provided as parameter
##
ENTRYPOINT ["/lap-entrypoint.sh"]









FROM tex

## For testing without tex
# FROM alpine:3.18.4

# unfortunately the alpine consortium feels unable to maintain reasonable versions of php
# this is why we build it from source

ENV  PHP_VERSION=php-8.2.0

### MUST also adapt the minor version for php82-apache below !!

###
### BUILD PHP 
###
RUN apk --no-cache update  && \
    apk --no-cache upgrade && \
    apk add --no-cache libxml2 curl oniguruma libpng libjpeg-turbo libxpm freetype libzip openssl pcre bzip2       --virtual runtimes && \
    apk --no-cache add autoconf gcc g++ make cmake pkgconf bison build-base re2c                                   --virtual build-tools && \
    apk --no-cache add curl-dev libxml2-dev sqlite-dev oniguruma-dev libpng-dev libjpeg-turbo-dev libxpm-dev \
      freetype-dev libzip-dev pcre-dev openssl-dev bzip2-dev icu-dev                                               --virtual build-deps  && \
    wget https://www.php.net/distributions/$PHP_VERSION.tar.gz --directory-prefix /tmp && \
    tar -xf /tmp/$PHP_VERSION.tar.gz --directory /tmp && \
    cd "/tmp/$PHP_VERSION"  && \
    ./configure   \
      --prefix=/usr/local \
      --with-openssl \
      --with-avif  --with-jpeg  --with-xpm  --with-webp \
      --with-curl \
      --with-pear \
      --with-zlib \
      --with-mysqli \
      --with-pdo-mysql \
      --enable-cli \
      --enable-bcmath \
      --enable-exif \
      --enable-ftp \
      --enable-fpm \
      --enable-intl \
      --enable-xml \
      --enable-mbstring \
      --enable-opcache \
      --enable-calendar && \
    make   -j 12     &&   \
    make install &&  \  
    make clean   &&  \
    apk del -r build-tools build-deps && \
    rm -rf /var/cache/apk/*   && \
    rm -rf "/tmp/*"   

##
## BUILD PHP APCU
##
RUN apk --no-cache update  && \
    apk --no-cache upgrade && \
    apk --no-cache add autoconf gcc g++ make cmake build-base --virtual build-tools-apcu && \
    cd /opt && \
    wget https://pecl.php.net/get/apcu-5.1.22.tgz && \
    tar -xzf apcu-5.1.22.tgz && \
    cd apcu-5.1.22 && \
    phpize && \
    ./configure --enable-apcu && \
    make && \
    make install && \
    make clean && \
    echo "extension=apcu.so" | sudo tee -a /etc/php8/php.ini && \
    php -m  && \
    apk del -r build-tools-apcu && \
    rm -rf /var/cache/apk/*   && \
    rm -rf "/tmp/*"   


########## TODO php.ini check stuff !!!!!!!!!!!!!!
########## TODO: clean sources in /opt

##
## INSTALL COMPOSER 
##
#   Mediawiki needs php dependency tool composer
#   This is a bit tricky and only this helped: https://stackoverflow.com/questions/51443557/how-to-install-php-composer-inside-a-docker-container

RUN apk --no-cache update   && \
    apk --no-cache upgrade  && \
    apk add --no-cache libstdc++ curl --virtual build-tools-composer && \
    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer && \
    apk del -r build-tools-composer  && \
    rm -rf /var/cache/apk/*          && \
    rm -rf "/tmp/*"   

##
##  INSTALL APACHE and its dependencies
##
RUN apk --no-cache add apache2 && \
    apk --no-cache add nghttp2-libs apache2-http2 nghttp2 apache2-proxy apache2-ssl php82-apache2 ca-certificates && \
#   make the required run pid directory /run/apache2 for apache
    mkdir -p /run/apache2                      &&  \
#   make the html mount point for apache /var/www/html
    mkdir -p /var/www/html                     &&  \
#   remove alpine container mount point
    rm -Rf /var/www/localhost       &&  \
    rm -rf /var/cache/apk/*    && \
    rm -rf "/tmp/*"   

##
##  INSTALL MEDIAWIKI RUNTIME dependenices 
##
#     diffutils       needed for text differences
#     git             needed to get proper hashes in Special:Version and in other places
#     imagemagick     needed for thumbnail construction
#     djvulibre       needed for djvu support
#     librsvg         needed for svg support
#     poppler-utils   needed as replacement for xpdf for which there seems to be no alpine package
RUN  \
    apk --no-cache add diffutils git imagemagick djvulibre librsvg netpbm && \
#   No xpdf in Alpine - using poppler-utils as replacement
    apk --no-cache add poppler-utils && \
##
##   mscgen is needed for mediawiki extension Diagrams and has no package in Alpine
##
    cd '/tmp' && \
    curl -fsSL "http://www.mcternan.me.uk/mscgen/software/mscgen-static-0.20.tar.gz" -o '/tmp/mscgen.tar.gz' && \
    tar -zxvf '/tmp/mscgen.tar.gz' && \
    mkdir -p /opt/mscgen  && \
    mv /tmp/mscgen-0.20/bin/mscgen /opt/mscgen/ && \
    rm -rf /tmp/*   && \
    rm -rf /var/cache/apk/*

##
##  INSTALL FURTHER TOOLS
##
#   aws-cli           need access to aws client tools for backup to aws
#   mysql-client      make dumps and restores via webserver interaction and via mediawiki special pages
#   msmtp             write simple mails to inform about backup job completion and more
#   bash              need the bash interpreter for the scripts to initialize mediawiki
#   coreutils         need tail for CMD to keep container runnign in any case
RUN  apk --no-cache add aws-cli  mysql-client  msmtp  bash  coreutils && \
     rm -rf /tmp/*                                     && \
     rm -rf /var/cache/apk/*

##
## COPY in docker context
##
COPY . .

##
## Default parameters for the entrypoint script below
##
CMD ["run-apache.sh"]

##
## Specify entrypoint, which will itself execute scripts provided as parameter
##
ENTRYPOINT ["/lap-entrypoint.sh"]
FROM tex

ENV PHP_INI_DIR /etc/php/7.4

RUN apk --no-cache update &&   \
    apk --no-cache upgrade &&  \
#   *** PHP    
    apk --no-cache add php7 && \
#   *** PHP extensions as required for Mediawiki       
    apk --no-cache add php7-session php7-openssl php7-json  php7-mbstring  php7-fileinfo php7-intl php7-calendar php7-ctype php7-xml php7-xmlreader php7-xmlwriter php7-simplexml php7-curl && \
#   *** Some more PHP extensions as they may seem useful
    apk --no-cache add  php7-bcmath php7-exif php7-ftp php7-dom php7-tokenizer php7-posix php7-iconv && \
#   MYSQL integration for php
    apk --no-cache add php7-mysqli &&\
#   *** apcu, igbinary and opcache as needed as suggested by mediawiki optimization    
    apk --no-cache add php7-apcu php7-igbinary php7-opcache && \
#   APACHE PHP integration: VARIANT 1: php7-fpm (see README)
    apk --no-cache add php7-fpm && \
#   APACHE PHP integration: VARIANT 2: php7-apache2 (see README)
    apk --no-cache add php7-apache2 && \
#   php phar is needed for composer, further down
    apk --no-cache add php-phar && \
#   PEAR will temporarily need a c compiler and a make utility
    apk --no-cache add g++ make && \
#   * PHP UTILITIES:  pear and pecl are needed for installing the DS data type, which we need in Parsifal for cleaning up #### TODO: do we still use this ???
    apk --no-cache add php7-dev php-pear && \
#   * honor an explicit request by pecl
    pecl channel-update pecl.php.net && \
#   * install ds
    pecl install ds && \
#   * enable proper https resolution for apache
    apk --no-cache add ca-certificates &&\ 
#   Mediawiki needs php dependency tool composer
#   this is a bit tricky and only this helped: https://stackoverflow.com/questions/51443557/how-to-install-php-composer-inside-a-docker-container
    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer && \
#   * APACHE
    apk --no-cache add apache2 && \
#   requirement for http2
    apk --no-cache add nghttp2-libs apache2-http2 && \
#   * APACHE MODULES     
    apk --no-cache add nghttp2 apache2-proxy apache2-ssl &&\
#   * diff utils needed for text differences
    apk --no-cache add diffutils && \
#   git needed to get proper hashes in Special:Version and in other places
    apk --no-cache add git &&\         
#   THUMBNAIL support in mediawiki
    apk --no-cache add imagemagick php7-gd  && \
#   DJVU support in mediawiki
    apk --no-cache add djvulibre && \
#   netpbm support in mediawiki
################    apk --no-cache add netpbm  && \       
#   No xpdf in Alpine - using poppler-utils as replacement
    apk --no-cache add poppler-utils && \
#   SVG support in mediawiki
    apk --no-cache add librsvg && \
#   /run/apache2 is pid directory for apache
    mkdir -p /run/apache2 &&                          \
#   /var/www/html is the html mount point
    mkdir -p /var/www/html &&                         \
#   remove remaining alpine container mount point
    rm -Rf /var/www/localhost && \
#   need access to aws client tools for the backup system to aws
    apk --no-cache add aws-cli && \
#   need mysql client cli to make dumps and restores via webserver interaction and via mediawiki special pages
    apk --no-cache add mysql-client && \
#   need msmtp to write simple mails to inform about backup job completion and more
    apk --no-cache add msmtp && \
#
    echo "*** *** Doing cleanups of layer "   && \
    apk del g++ make && \
#   cleanup
    rm -Rf /var/cache/apk/*

## COPY in docker context
COPY . .

# Expose for http and https
EXPOSE 80
EXPOSE 443

ENTRYPOINT ["/lap-entrypoint.sh"]
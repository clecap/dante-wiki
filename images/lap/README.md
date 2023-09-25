
LAP is a LINUX APACHE PHP stack (without MySQL or other DB), configured for the purposes of the DANTE project.

# Usage

`generate.sh` generate the image from the dockerfile and docker context in /src

# Additional Files #




# Apache / PHP Remarks #

## PHP Integration ##


### Situation ###
The container provides two different possibilities for a PHP integration:
* PHP FPM
* MOD_PHP

### Reason ###

PHP FPM is the more efficient and modern integration. However, we had some cases of unexplained crashes
due to PHP problems in FPM which did not show up in MOD_PHP. We therefore want an easy possibility of 
switching integrations without rebuilding images.

### Architecture ###

The Dockerfile contains the libraries for both integrations. The choice between the integration to be used
is made by an environment variable which gets picked up by the entrypoint shell script. Based on this
environment variable the entrypoitn shell script then picks the correct configuration file for the Apache.

### httpd.conf ###
* In the Alpine configuration, httpd.conf loads a number of modules, which we do not want to have loaded.
* We cannot prevent this using later config files since conf.d is loaded later.
* Patching using this using sed is unreliable so we decided to copy in the complete httpd.conf file.
* Therefore we upload a (minimally) patched hgttpd.conf where we take out the unwanted modules.
* Here: Disable those in conflict with php (see https://stackoverflow.com/questions/42506956/sudo-a2enmod-php5-6-php-v-still-shows-php-7-01-conflict )
**  Disable: mpm_prefork mpm_worker mpm_event

### Info ###
* The modules are in /usr/lib/apache2

## Conventions ##
For Dante we use the following conventions:

/var/www/html is the starting point for the served pages.

/var/www/html/wiki-NAME is the starting point for the wiki of name NAME

NAME must conform to [a-zA-Z0-9_]+

/var/www/html/dir is the starting point for other files and directories.
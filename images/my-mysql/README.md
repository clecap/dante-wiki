

my-mysql is a mariadb image constructed on top of alpine linux.

The name my-mysql is used since the name mysql already has a meaning in dockerhub.


`add-user.sh  USERNAME  PASSWORD`         adds a user to the database

`admin.sh` attach a PHP myadmin container to a running database

`generate.sh` generate a mysql image from a dockerfile

`run.sh `    run a mysql container


`dbDump.sh` writes a dump of the entire database to TOPLEVEL/dumps/

`dbRestore.sh` restores a dump from TOPLEVEL/dumps
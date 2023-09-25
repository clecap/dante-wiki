# volumes/full #

`volumes/full` is the working area a full blown dante / mediawiki / parsifal plus wordpress development environment.

### Sub-Directories ###
It consists of the following sub-directories:

* `/content`: This is the area we are using. This is the mount point for the directory or volume.
  * This directory may be structured into various directories which may contain individual tests
  * This directory contains `wiki-dir` as main Mediawiki test directory.
* `/spec` contains shell scripts for reconstructing the `/content` completely.
* `/src` contains a few files of general interest, which may be copied in to `/content`via shell files.
* `/spec` contains shel scripts for generating `/content`
* `/experiments`contains temporary files for small experiments which we need to have under web server control

### Content-Source ###
Where does the content come from?
* The `internet` (mediawiki.org, wordpress.org and others)
* The `src` directory (this is under control of github.com/clecap/continuous-deployment-test)
  * Contains a few files of general interest (such as site-wide favicon)
  * This content is under version control in the top-level continuous-deployment-test repository.
* `clecap/dante-delta` (github.com/clecap/dante-delta)
  * This repository contains smaller elements which we edit and which do not have their own fully blown repository.
  

* `clecap/Parsifal` (github.com/Parsifal)
  * This repository (and later probably others) contains large, stand alone code, which warrants it's own repository.
  * Version control: via git-clone-dante-from-parsifal.sh and git-push-to-parsifal.sh
  * .gitignore is in Parsifal directory inside of wiki-dir/extensions/Parsifal
* `dynamically generated` by a shell-script in the context of a running webserer and database. (For example: LocalSettings.php is dynamically generated)

### Version Control ###
How is the content version-controlled?

* The content from the internet is just pulled in.
* The content

### Content-Construction ###
* `cmd.sh` pulls in various sources of mediawiki, wordpress etc from the network as well as from directory `/src`
* `wiki-init.sh` generates files which we can only reasonably construct in the context of a running database and webserver environment



The


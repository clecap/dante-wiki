All configuration related files are kept inside of this directory private/

In order to make a configuration for a host of name <NAME> we execute 

  make-config.sh <NAME>

  <NAME> must be a regular hostname, in particular it may not contain any slash or any double-dots ..

This script then looks at the directory private/<NAME>. There is takes the file
named private/<NAME>/source-configuration.sh, processes it and generates a fresh
file named private/<NAME>/configuration.sh.

The processing does the following:

Whereever the file private/<NAME>/source-configuration.sh contains a text line starting with

IMPORT <filename>

it checks that the <filename> contains only the name fo a normal file, without slashes, double dots or paths.

it replaces this line by 
FIRST:   an empty line
SECOND:  a shell comment of this form:   # BEGIN importing file <filename>
THIRD:   the contents of the file <filename> from the subdirectory LIB in the directory private/.
FOURTH:  a shell comment of this form:    # END importing file <filename>
FIFTH:   an empty line

Whereever the file private/<NAME>/source-configuration.sh contains any other line, this line is
reproduced as it is, whatever it is, a comment, a text-line or a shell command.

The location of the directory private/ is to be found relative to the location of where the
script make-config.sh itself resides (not relative to the working directory of the shell in which
it is executed). If make-config.sh is located in directory <DIR> then we look for directory
private/ to be a subdirectory of the partent directory of <DIR>.




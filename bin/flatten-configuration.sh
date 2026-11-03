#!/bin/bash

#
# Writes a single file in which every "source FILE" or ". FILE" line of CONFIG is replaced by the content
# of FILE, recursively. Comments, order and overrides are kept, so sourcing the result gives the same values
# as sourcing CONFIG. Nothing from the configuration is executed, this is pure text processing.
#
# Usage: flatten-configuration.sh CONFIG > flat.sh
#
# Relative paths are resolved from the folder of CONFIG, as bash does when CONFIG is sourced from there.
# Paths must be written literally: a path containing variables, like "$DIR/mail.sh", cannot be resolved.
#

if [ $# -ne 1 ]; then
  echo "Usage: $0 CONFIG > flat.sh" >&2
  exit 1
fi

if [ ! -f "$1" ]; then
  echo "$0: file not found: $1" >&2
  exit 1
fi

CONFIG=$(realpath "$1")

awk '
  function inline(file,    line, path, full) {
    while ((getline line < file) > 0) {
      if (line ~ /^[ \t]*(source|\.)[ \t]+/) {
        path = line
        sub(/^[ \t]*(source|\.)[ \t]+/, "", path)       # strip the keyword
        sub(/[ \t]*(#.*)?$/, "", path)                   # strip a trailing comment
        gsub(/["\047]/, "", path)                        # strip quotes
        if (path ~ /\$/) fail("cannot resolve a path containing variables: " line " (in " file ")")
        full = (path ~ /^\//) ? path : dir "/" path
        if ((getline test < full) < 0) fail("cannot read " full " (sourced in " file ")")
        close(full)
        print "# ---- begin " path " ----"
        inline(full)
        print "# ---- end " path " ----"
      } else
        print line
    }
    close(file)
  }
  function fail(msg) { print "flatten-configuration.sh: " msg > "/dev/stderr"; failed = 1; exit 1 }
  BEGIN { dir = ARGV[1]; sub(/\/[^\/]*$/, "", dir); inline(ARGV[1]); exit }
' "$CONFIG"

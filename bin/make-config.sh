#!/bin/bash

#
# Generates private/<NAME>/configuration.sh from private/<NAME>/source-configuration.sh.
#
# Usage: make-config.sh <NAME>
#
# Every line of the form   IMPORT <filename>   is replaced by the contents of private/LIB/<filename>,
# framed by an empty line and a BEGIN / END comment. All other lines are copied unchanged.
# Imports are not processed recursively. Nothing from the configuration is executed.
#
# See doc/README-make-configurations.md
#


set -u

fail() { echo "$(basename "$0"): $*" >&2; exit 1; }

if [ $# -ne 1 ]; then
  echo "Usage: $0 <NAME>" >&2
  exit 1
fi

NAME="$1"

# NAME must be a regular hostname: letters, digits, dots and hyphens, no slash, no double dots
if [[ ! "$NAME" =~ ^[A-Za-z0-9]([A-Za-z0-9.-]*[A-Za-z0-9])?$ ]] || [[ "$NAME" == *..* ]]; then
  fail "not a valid hostname: $NAME"
fi

# private/ is a subdirectory of the parent of the directory in which this script resides
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
PRIVATE="$(dirname "$SCRIPT_DIR")/private"
LIB="$PRIVATE/LIB"
HOST_DIR="$PRIVATE/$NAME"
SOURCE="$HOST_DIR/source-configuration.sh"
TARGET="$HOST_DIR/configuration.sh"

[ -d "$PRIVATE" ]  || fail "directory not found: $PRIVATE"
[ -d "$HOST_DIR" ] || fail "directory not found: $HOST_DIR"
[ -f "$SOURCE" ]   || fail "file not found: $SOURCE"

# No temporary files are used, since the contents are confidential.
# Pass 1 (check) validates all IMPORT lines without writing anything, so that a bad source file
# never destroys an existing configuration.sh. Pass 2 (emit) writes the result to stdout.
process() {
  local mode="$1" line FILE WHERE n=0
  # "|| [ -n "$line" ]" also handles a last line without a trailing newline
  while IFS= read -r line || [ -n "$line" ]; do
    n=$((n + 1))
    if [[ "$line" =~ ^IMPORT([[:space:]]|$) ]]; then
      # extract the filename: everything after IMPORT, surrounding whitespace removed
      FILE="${line#IMPORT}"
      FILE="${FILE#"${FILE%%[![:space:]]*}"}"
      FILE="${FILE%"${FILE##*[![:space:]]}"}"
      if [ "$mode" = check ]; then
        WHERE="$SOURCE line $n"
        [ -n "$FILE" ]                     || fail "IMPORT without filename ($WHERE)"
        [[ "$FILE" != */* ]]               || fail "IMPORT filename must not contain a slash: $FILE ($WHERE)"
        [[ "$FILE" != *..* ]]              || fail "IMPORT filename must not contain double dots: $FILE ($WHERE)"
        [[ "$FILE" =~ ^[A-Za-z0-9._-]+$ ]] || fail "IMPORT filename contains invalid characters: $FILE ($WHERE)"
        [ -f "$LIB/$FILE" ] && [ -r "$LIB/$FILE" ] || fail "cannot read $LIB/$FILE ($WHERE)"
      else
        echo ""
        echo "# BEGIN importing file $FILE"
        cat "$LIB/$FILE" || return 1
        # make sure the END comment starts on a line of its own
        [ -z "$(tail -c 1 "$LIB/$FILE")" ] || echo ""
        echo "# END importing file $FILE"
        echo ""
      fi
    elif [ "$mode" = emit ]; then
      printf '%s\n' "$line"
    fi
  done < "$SOURCE"
}

process check

# the generated file is readable only by the owner (also when it already existed)
umask 077
if [ -e "$TARGET" ]; then
  chmod 600 "$TARGET" || fail "cannot set permissions of $TARGET"
fi
process emit > "$TARGET" || fail "error while writing $TARGET"
echo "Generated $TARGET"

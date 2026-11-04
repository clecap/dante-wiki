#!/bin/bash

#
# Computes the next version from the commit messages since the last version tag.
#
# Usage: next-version.sh [FIRST_RANGE]
#   FIRST_RANGE: commit range to look at when no version tag exists yet (default: HEAD only)
#
# The version lives in git tags of the form vMAJOR.MINOR.PATCH; without such a tag we start at 0.0.0.
# A commit message (first line) starting with
#   break:  increases MAJOR (and resets MINOR and PATCH to 0)
#   feat:   increases MINOR (and resets PATCH to 0)
#   bump:   increases PATCH
# Several commits since the last tag lead to one increase, of the highest kind found.
#
# Prints the new version (without "v"), or nothing if no commit asks for an increase.
#

set -euo pipefail

LAST_TAG=$(git describe --tags --abbrev=0 --match 'v[0-9]*.[0-9]*.[0-9]*' 2>/dev/null || true)

if [ -n "$LAST_TAG" ]; then
  RANGE="$LAST_TAG..HEAD"
  LAST=${LAST_TAG#v}
else
  RANGE=${1:-HEAD^!}
  LAST=0.0.0
fi

SUBJECTS=$(git log --format=%s "$RANGE")

IFS=. read -r MAJOR MINOR PATCH <<< "$LAST"

if   grep -q '^break:' <<< "$SUBJECTS"; then MAJOR=$((MAJOR + 1)); MINOR=0; PATCH=0
elif grep -q '^feat:'  <<< "$SUBJECTS"; then MINOR=$((MINOR + 1)); PATCH=0
elif grep -q '^bump:'  <<< "$SUBJECTS"; then PATCH=$((PATCH + 1))
else exit 0
fi

echo "$MAJOR.$MINOR.$PATCH"

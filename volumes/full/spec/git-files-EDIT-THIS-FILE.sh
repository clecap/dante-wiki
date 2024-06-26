#!/bin/bash

# This file defines those content elements of volumes/full which are under control of a local git
# That way we can work on minor parts of dante mediawiki without always having to generate a big repository for a tiny extension or skin

# NOTE: Shell lists do not have a comma separator

##
## CAVE: WHen we change this here we must also change .gitignore in wiki-dir (=dante-delta)
##

declare -a MY_FILES=(                  \
  "README-dantepatch.md"               \
  "includes/import/WikiImporter.php"   \
  "includes/media/SVGReader.php"   \
  "DantePolyfill.php"                  \
  "DanteSettings.php"                  \
  "DanteSettings-production.php"       \ 
  "DanteSettings-development.php"      \
  "DanteSettings-used.php"             \
   "README-dante-delta.md"             \
   ".gitignore")

declare -a MY_DIRECTORIES=(        \
  "extensions/DanteSynch"          \
  "extensions/DanteHideSection"    \ 
  "extensions/DanteBread"          \ 
  "extensions/DanteLinks"          \ 
  "extensions/DanteSnippets"       \
  "extensions/DanteTree"           \
  "extensions/DantePresentations"  \
  "extensions/DanteBackup"         \
  "extensions/DanteSyntax"         \
  "skins/skinny"                   \
  "skins/DantePresentationSkin")


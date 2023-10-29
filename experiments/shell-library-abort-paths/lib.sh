#!/bin/bash

# propagate traps into called functions:
set -E

set -o functrace

# See https://stackoverflow.com/questions/24398691/how-to-get-the-real-line-number-of-a-failing-bash-command

function handle_error {
  # get exit status of last executed command
  local retval=$?
  local line=${last_lineno:-$1}
  local arg1=$1
  local arg2=$2
  local argLast=${@: -1}
  printf "\e[1;31m***\n*** ERROR at CMD $argLast in LINE: $line of FILE: ${BASH_SOURCE[1]} with STATUS: $retval \n***\n\n     STACK TRACE:\n\n"
  for i in "${!FUNCNAME[@]}"
    do
      printf "    \e[1;31m FCT %-15s called in FILE %-15s at LINE %-15s\n" ${FUNCNAME[$i]}  ${BASH_SOURCE[$i+1]}  ${BASH_LINENO[$i]}
    done
    exit $retval
}

# See https://stackoverflow.com/questions/24398691/how-to-get-the-real-line-number-of-a-failing-bash-command
if (( ${BASH_VERSION%%.*} <= 3 )) || [[ ${BASH_VERSION%.*} = 4.0 ]]; then
  trap '[[ $FUNCNAME = handle_error ]] || { last_lineno=$real_lineno; real_lineno=$LINENO; }' DEBUG
fi
trap 'handle_error $LINENO ${BASH_LINENO[@]} $BASH_COMMAND' ERR


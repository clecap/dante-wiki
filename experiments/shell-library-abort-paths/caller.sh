#!/bin/bash

source lib.sh

sub () {
  printf " I am in %10s" ${FUNCNAME[0]} " called\n "
  subsub
}

# called may be defined later than the place it is called

subsub () {
  echo "i am in subsub"
  subsubsub
}

subsubsub () {
  echo "i am in subsubsub"
  humbug
}

sub
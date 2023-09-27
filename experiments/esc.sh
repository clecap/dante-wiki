#!/bin/bash


ARGU_EINS="One two three"

ARGU_ZWEI="Abra"

fun () {

 printf "*** fun called with $# positional parameters \n\n"

}

fun "${ARGU_EINS}"  "${ARGU_ZWEI}"



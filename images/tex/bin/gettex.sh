#!/bin/bash

# This script does an rsync and generates a mirror of the tex-archive on the local machine

rsync -avzh --progress --delete rsync://mirror.informatik.hs-fulda.de/ctan /Users/cap/Documents/tex-archive
#!/usr/bin/env bash

# This script exists to simply wrap HandBrakeCLI but write the output to a file
# instead of STDERR. It takes 1 manadatory arg (which is always first) for the
# log path and any other args are passed directly to HandBrakeCLI

LOG_PATH=$1
HandBrakeCLI ${@:2} &> $LOG_PATH

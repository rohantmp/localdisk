#!/bin/bash

set -m

# start lsmd in the background
/usr/bin/lsmd &
PID=$!

# use lsmcli
lsmcli $@


#!/usr/bin/env sh
#
# Ping Identity DevOps - Docker Build Hooks
#
# This is called after the start or restart sequence has finished and before 
# the server within the container starts
#

# shellcheck source=../lib.sh
. "${BASE}/lib.sh"

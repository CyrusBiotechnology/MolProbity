#!/bin/sh
# Read in the file of environment settings
. /build/setpaths.sh
# Then run the CMD
exec "$@"


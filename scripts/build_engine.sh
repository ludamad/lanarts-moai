#!/bin/bash

###############################################################################
# Build the engine, forwarding any build flags to ./engine/build.sh
# If the engine does not exist, first clone the engine source.
###############################################################################

set -e # Good practice -- exit completely on any bad exit code

# Navigate to base folder:
cd "`dirname "$0"`"/.. 

# Set common variables and shell-script safety settings
source "scripts/common.sh"

BASE_FOLDER="$(pwd)"
ENGINE="$BASE_FOLDER/$ENGINE_FOLDER"

if [ ! -e "$ENGINE" ] ; then
    echo "Cloning $ENGINE_CLONE_URL into \"$ENGINE\"..." | colorify $LIGHT_BLUE
    git clone "$ENGINE_CLONE_URL" "$ENGINE"
    echo "Cloned $ENGINE_CLONE_URL into \"$ENGINE\"." | colorify $YELLOW
fi

bash "$ENGINE/build.sh" $@

###############################################################################
# Copy the engine lua-deps/ folder to .lua-deps/
###############################################################################

rm -rf "$BASE_FOLDER/.lua-deps/"
cp -r "$ENGINE/builds/lua-deps/" .lua-deps/

#!/bin/bash

###############################################################################
# Run the game, first building the engine.
###############################################################################

set -e # Good practice -- exit completely on any bad exit code

# Navigate to base folder:
cd "`dirname "$0"`"

# Set common variables and shell-script safety settings
source "scripts/common.sh"

BASE_FOLDER="$(pwd)"

###############################################################################
# Build the engine, potentially downloading it first.
###############################################################################

if [ ! -e engine/builds/native/ ] || handle_flag "--build" || handle_flag "-B" ; then
    bash ./scripts/build_engine.sh $@
fi

###############################################################################
# Run the engine, using 'main.lua'.
###############################################################################

BUILD_ROOT="$BASE_FOLDER/$ENGINE_FOLDER/builds/"
EXECUTABLE="$BUILD_ROOT/dist/moai"
FLAGS="$BUILD_ROOT/dist/loader.lua $BUILD_ROOT/dist"  

if handle_flag "--gdb" || handle_flag "-g" ; then
    echo "Wrapping in GDB:" | colorify '1;35'
        #-ex="break SetLanartsOpenWindowFullscreenMode" \
    gdb -silent -quiet \
        -ex='set confirm off' \
        -ex='source scripts/luajit.py' \
        -ex=r --args \
        "$EXECUTABLE" $FLAGS main $args
else
    exec "$EXECUTABLE" $FLAGS main $args
fi

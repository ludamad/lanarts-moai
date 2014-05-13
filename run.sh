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

EXECUTABLE="$BASE_FOLDER/$ENGINE_FOLDER/builds/native/dependencies/external/moai-dev/cmake/host-sdl/moai"

"$EXECUTABLE" src/lua/main.lua $@

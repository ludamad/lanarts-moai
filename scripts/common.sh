#!/bin/bash

###############################################################################
# Common parameters and settings for shell scripts used throughout.
###############################################################################

set -u # Ensure undefined variables are an error
set -e # Good practice -- exit completely on any bad exit code

###############################################################################
# Location constants.
###############################################################################

ENGINE_FOLDER=engine
ENGINE_CLONE_URL=https://github.com/ludamad/moai-experimenting

###############################################################################
# Colour constants for 'colorify'.
###############################################################################

BLACK='0;30'
DARK_GRAY='1;30'
BLUE='0;34'
LIGHT_BLUE='1;34'
GREEN='0;32'
LIGHT_GREEN='1;32'
CYAN='0;36'
LIGHT_CYAN='1;36'
RED='0;31'
LIGHT_RED='1;31'
PURPLE='0;35'
LIGHT_PURPLE='1;35'
BROWN='0;33'
YELLOW='1;33'
LIGHT_GRAY='0;37'
WHITE='1;37'

###############################################################################
# Helper functions for conditionally coloring text.
###############################################################################

function is_mac() {
    if [ "$(uname)" == "Darwin" ]; then
        return 0 # True!
    else
        return 1 # False!
    fi
}

# Bash function to apply a color to a piece of text.
function colorify() {
    if is_mac ; then
        cat
    else
        local words;
        words=$(cat)
        echo -e "\e[$1m$words\e[0m"
    fi 
}

###############################################################################
# Bash function to check for a flag in 'args' and remove it.
# Treats 'args' as one long string. 
# Returns true if flag was removed.
###############################################################################

args="$@" # Create a mutable copy of the program arguments
function handle_flag(){
    flag=$1
    local new_args=""
    local got
    got=1 # False!
    for arg in $args ; do
        if [ $arg = $flag ] ; then
            args="${args/$flag/}"
            got=0 # True!
        else
            new_args="$new_args $arg"
        fi
    done
    args="$new_args"
    return $got # False!
}

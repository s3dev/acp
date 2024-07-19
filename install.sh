#!/usr/bin/env bash
#-------------------------------------------------------------------------
# Prog:     install.sh
# Version:  n/a
# Desc:     Primary installer script for the acp project.
#
#           After prompting the user for the installation directory, this
#           script calls make to carry out the installation.
#
# Use:      $ ./install.sh
#
#               Follow the prompts ...
#
# Updates:
# 19-07-24  J. Berendt  Written
#-------------------------------------------------------------------------

# Initialise.
_dst=
_dst_default="/usr/local/bin"

#
# Call make to complete the installation with the user-provided 
# installation directory.
#
function call_make() {
    make dst="$_dst"
}

#
# Prompt the user for acp's deployment path.
#
# If a path does not exist, it is created.
#
function get_deploy_path() {
    local __dst=
    printf "Enter the desired deployment path for acp, or leave blank to accept the default.\n"
    printf " -- The default path is: %s\n\n" $_dst_default
    read -p "Path: " __dst
    if [ -z $__dst ]; then
        _dst=$_dst_default
    else
        _dst="$__dst"
        [ ! -d $__dst ] && mkdir -p $__dst
    fi
}

#
# Print the installer's startup message.
#
function startup() {
    cat << EOF

    -----------------
      acp Installer
    -----------------

EOF
}

#
# Primary controller and entry point.
#
function main() {
    startup
    [ $? -eq 0 ] && get_deploy_path
    [ $? -eq 0 ] && call_make
}

main


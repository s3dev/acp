#!/usr/bin/env bash
#-------------------------------------------------------------------------
# Script:   update-install
# Desc:     This script contains the functionality for acp's update/install
#           routine.
#
#           This script is designed to install the downloaded package 
#           metadata files into the apt directory: /var/lib/apt/lists.
#
#           Next steps:
#           Use the --upgrade --find arguments to find the packages which
#           can be upgraded.
#
# Usage:    $ acp --update --install path/to/update_<datetime>.tar
#
# Updates:
# 16-07-24  J. Berendt  Written.
#-------------------------------------------------------------------------

# Read config file and supporting functionality.
_dir="$( dirname "$( realpath "$0" )" )" 
. "$_dir/.config"
. "$_dir/utils.sh"

# Constants
_DIR_LISTS="/var/lib/apt/lists"
_DIR_UPDATES="/tmp/updates-install"

#
# Display the epilog message, instructing the user of the next step in the
# process.
#
function epilog() {
cat << EOF

The apt directory has been updated.

This was the equivalent of running the 'apt update' command on each target 
host. Next, the packages due for upgrade (as identified by the process just
completed) can be upgraded.

Next steps:
    From the offline system, run the following command to collect the packages
    which are due for upgrade and the URLs from which the latest packages can 
    be downloaded, for each target host.

        $ acp --upgrade --find

EOF
}

#
# Install the package metadata files for each host.
#
# The following steps are carried out on the .tar files which have been
# unpacked to the /tmp/updates-install directory:
#   - Derive the target's hostname from the .tar filename.
#   - Transfer the archive to the target host.
#   - Clean the apt directory (/var/lib/apt/lists) to remove all files.
#   - Extract the target host's package metadata files from the archive,
#     to the cleaned apt directory.
#   - Decompress the package metadata files (*.xz files) in the apt
#     directory.
#   - Remove all .xz files from the apt directory, as these can cause file
#     corruption, (e.g. the frequently seen 'lzma_read read error' with 
#     apt-offline).
#
# @return Always return 0.
#
function install() {
    local _base=
    local _fname=
    local _host=
    printf "Installing the package metadata files ...\n"
    for f in $_DIR_UPDATES/*.tar; do
        _base=$( basename "$f" )  # \
        _fname="${_base%%.*}"     #  --- Get the hostname from the filename.
        _host="${_fname##*-}"     # /
        printf " - for: %s\n" ${_host^^}
        scp "$f" $UID_OFFLINE@$_host:/tmp &> /dev/null
        ssh -t $UID_OFFLINE@$_host "pushd $_DIR_LISTS > /dev/null;" \
                                   "sudo rm -f ./* &> /dev/null;" \
                                   "sudo tar -xf $f -C $_DIR_LISTS --strip-components 3;" \
                                   "sudo xz -d *.xz &> /dev/null;" \
                                   "sudo rm *.xz &> /dev/null;" \
                                   "popd > /dev/null"
    done
    return 0
}

#
# Pre-run setup operations.
#
# @return Always return 0.
#
function setup() {
    echo
    # Create the /tmp/updates-install/* directories, if they don't exist.
    [ ! -d $_DIR_UPDATES ] && mkdir $_DIR_UPDATES
    printf "Removing old .tar files in %s ...\n" $_DIR_UPDATES
    rm $_DIR_UPDATES/*.tar > /dev/null 2>&1
    printf "Done.\n\n"
    return 0
}

#
# Unpack the provided archive containing the host's .tar files into the
# defined /tmp directory.
#
# @return Returns the exit code from the tar command.
#
function unpack() {
    tar -xf "$_INPATH" -C $_DIR_UPDATES
    return $?
}

#
# Entry-point and primary controller for the program.
#
function main() {
    setup
    [ $? -eq 0 ] && unpack
    [ $? -eq 0 ] && install
    [ $? -eq 0 ] && epilog
    return 0
}

# Store command line arguments.
_INPATH="$1"  # Path to the archive containing the .sig files.

main


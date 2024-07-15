#!/usr/bin/env bash
#-------------------------------------------------------------------------
# Script:   upgrade-install
# Desc:     This script contains the functionality for acp's 
#           upgrade/install routine.
#
#           This script is designed to install each target host's 
#           downloaded packages.
#
# Usage:    $ acp --upgrade --install path/to/upgrade_<datetime>.tar
#
# Updates:
# 17-07-24  J. Berendt  Written.
#-------------------------------------------------------------------------

# Read config file and supporting functionality.
_dir="$( dirname "$( realpath "$0" )" )" 
. "$_dir/.config"
. "$_dir/utils.sh"

# Constants
_DIR_INSTALL="/tmp/acpinstall"
_DIR_UPGRADES="/tmp/upgrades-install"

#
# Display the epilog message.
#
function epilog() {
cat << EOF


All system updates complete.


EOF
}

#
# Install the latest package(s) for each target host.
#
# The following steps are carried out on the .tar files which have been
# unpacked to the /tmp/upgrades-install directory:
#   - Derive the target's hostname from the .tar filename.
#   - Transfer the archive to the target host.
#   - Create a /tmp/acpinstall directory on the host.
#   - Unpack the .deb files from the archive.
#   - Install the .deb packages.
#   - Call autoremove to remove any packages which are no longer required.
#   - Call autoclean.
#
# @return Always return 0.
#
function install() {
    local _base=
    local _fname=
    local _host=
    printf "Installing updates ...\n"
    for f in $_DIR_UPGRADES/*.tar; do
        _base=$( basename "$f" )  # \
        _fname="${_base%%.*}"     #  --- Get the hostname from the filename.
        _host="${_fname##*-}"     # /
        printf " - for: %s\n" ${_host^^}
        scp "$f" $UID_OFFLINE@$_host:/tmp &> /dev/null
        # This runs dpkg -i twice to catch dependency issues.
        ssh -t $UID_OFFLINE@$_host "pushd /tmp > /dev/null;" \
                                   "[ ! -d $_DIR_INSTALL ] && mkdir -p $_DIR_INSTALL;" \
                                   "rm -f $_DIR_INSTALL/* &> /dev/null;" \
                                   "sudo tar -xf $f -C $_DIR_INSTALL;" \
                                   "sudo dpkg -i $_DIR_INSTALL/*.deb;" \
                                   "sudo dpkg -i $_DIR_INSTALL/*.deb;" \
                                   "popd > /dev/null;" \
                                   "sudo apt autoremove -y;" \
                                   "sudo apt autoclean;"
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
    # Create the /tmp/upgrades-install/* directories, if they don't exist.
    [ ! -d $_DIR_UPGRADES ] && mkdir $_DIR_UPGRADES
    printf "Removing old files in %s ...\n" $_DIR_UPGRADES
    rm $_DIR_UPGRADES/* > /dev/null 2>&1
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
    tar -xf "$_INPATH" -C $_DIR_UPGRADES
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
    #return 0
}

# Store command line arguments.
_INPATH="$1"  # Path to the archive containing the .sig files.

main


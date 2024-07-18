#!/usr/bin/env bash
#-------------------------------------------------------------------------
# Script:   upgrade-find
# Desc:     This script contains the functionality for acp's upgrade/find
#           routine.
#
#           This script wraps the 'apt upgrade' command, which is used to
#           collect and store the URIs from which the latest packages can
#           be downloaded.
#
#           Next steps:
#           Use the --upgrade --get PATH arguments to download the latest
#           package from the listed URIs and checksum the downloaded 
#           files.
#
# Usage:    $ acp --upgrade --find
#
# Updates:
# 16-07-24  J. Berendt  Written.
#-------------------------------------------------------------------------

# Read config file and supporting functionality.
_dir="$( dirname "$( realpath "$0" )" )" 
. "$_dir/.config"
. "$_dir/utils.sh"

# Constants
_DIR_UPGRADES="/tmp/upgrades"

#
# Archive the .sig files from the staging area to the user's desktop as
# a .tar archive file.
#
# @return Returns the exit code from the move command, which moves the
#         archive from the staging area to the user's desktop.
#
function archive() {
    local _fname="$_DIR_UPGRADES/upgrade_$( date +%Y%m%d%H%M%S ).tar"
    local _excode=
    printf "Archiving the *.sig files ...\n"
    pushd $_DIR_UPGRADES > /dev/null  # Hack tar to get the desired directory structure.
    tar -cvf "$_fname" *.sig
    popd > /dev/null
    mv "$_fname" "$HOME/Desktop"
    _excode=$?
    printf "Done.\n\n"
    printf "${GRN}The signature files are ready for transport and located here:\n"
    printf "\t- %s${RST}\n" "$HOME/Desktop/$( basename $_fname )"
    return $_excode
}

#
# Create a .sig file, for each hostname listed in the .config file.
#
# Each .sig file contains the URI from which the latest package can be
# downloaded, and the expected MD5 checksum for the file.
#
# @return Returns 0 always, to enable archiving.
#
function create_sig() {
    for host in ${HOSTS[@]}; do
        printf "Collecting upgrade information for: %s\n" $host
        runcmd $host
        [ $? -eq 0 ] && printf "Complete.\n\n"
    done
    # Always return 0 to enable archiving.
    return 0
}

#
# Display the epilog message, instructing the user of the next step in the
# process.
#
function epilog() {
cat << EOF

Next steps:
    Copy the appropriate upgrade_*.tar file, from the location mentioned
    above, to the online system and run:
        
        $ acp --upgrade --get path/to/upgrade_<datetime>.tar

EOF
}

#
# SSH into the node and run the apt upgrade --print-uris command and store
# into a .sig file. Once complete, the .sig file is SCP'd back to the 
# localhost.
#
# @param $1 Hostname for the target node against which the update command
#           is to be run. Note: The hostname must be in /etc/hosts.
#
# @return Return 0 if all operations complete successfully, otherwise 1.
#
function runcmd() {
    local _node="$1"
    local _fpath="/tmp/upgrade-${_node,,}.sig"
    local _cmd1="apt upgrade --print-uris 2> /dev/null | grep ^\'http | tr -d \' > $_fpath"
    local _cmd2="apt install -f --print-uris 2> /dev/null | grep ^\'http | tr -d \' >> $_fpath"
    if is_alive $_node; then
        ssh -t $UID_OFFLINE@$_node "$_cmd1; $_cmd2"
        if [ $? -eq 0 ]; then
            scp $UID_OFFLINE@$_node:"$_fpath" "$_DIR_UPGRADES"
        else
            printf "${RED}An error occurred while running the upgrade command for %s.{$RST}\n\n" $_node
            return 1
        fi
    else
        printf "Node (%s) is down, not collecting.\n\n" $_node
        return 1
    fi
    return 0
}

#
# Run setup logic to prepare for the *.sig files.
#
# @return Always return 0.
#
function setup() {
    echo
    # Create the /tmp/upgrades directory, if it does not exist.
    [ ! -d $_DIR_UPGRADES ] && mkdir $_DIR_UPGRADES
    printf "Removing any old .sig files in %s ...\n" $_DIR_UPGRADES
    rm $_DIR_UPGRADES/*.sig &> /dev/null
    printf "Done.\n\n"
    return 0
}

#
# Main program controller.
#
# @return The return code from the archive function.
#
function main() {
    local _excode=
    setup
    [ $? -eq 0 ] && create_sig
    [ $? -eq 0 ] && archive
    _excode=$?  # Store archive's exit code as the next call will overwrite.
    [ $_excode -eq 0 ] && epilog
    return $_excode
}

main


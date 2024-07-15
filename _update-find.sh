#!/usr/bin/env bash
#-------------------------------------------------------------------------
# Script:   update-find
# Version:  0.1.0
# Desc:     This script contains the functionality for acp's update/find
#           routine.
#
#           This script wraps the 'apt --update' command, which is used to
#           collect and store the URIs required for downloading the 
#           contents for the /var/lib/apt/lists directory; triggered by
#           an apt --update.
#
#           Next steps:
#           Use the --update --get arguments to download the files from
#           the listed URIs, followed by the --update --install arguments
#           to move the downloaded files into the /var/lib/apt/lists 
#           directory.
#
# Updates:
# 11-07-24  J. Berendt  Written. Logic based on the cstmgt-update-collect
#                       script.
#-------------------------------------------------------------------------

# Read config file and supporting functionality.
_dir="$( dirname "$( realpath "$0" )" )" 
. "$_dir/.config"
. "$_dir/_utils.sh"

# Constants
_DIR_UPDATES="/tmp/updates"

#
# Archive the .sig files from the staging area to the user's desktop as
# a .tar archive file.
#
# @return Returns the exit code from the move command, which moves the
#         archive from the staging area to the user's desktop.
#
function archive() {
    local _fname="$_DIR_UPDATES/update_$( date +%Y%m%d%H%M%S ).tar"
    local _excode=
    printf "Archiving the *.sig files ...\n"
    pushd /tmp > /dev/null  # Hack tar to get the desired directory structure.
    tar -cvf "$_fname" updates/*.sig
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
# @return Returns 0 always, to enable archiving.
#
function create_sig() {
    for host in ${HOSTS[@]}; do
        printf "Collecting update for %s ...\n" $host
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
    Copy the appropriate update_*.tar file, from the location mentioned
    above, to the online environment and run:
        
        $ acp --update --get

EOF
}

#
# SSH into the node and run the apt update --print-uris command and store
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
    local _fpath="/tmp/update-${_node,,}.sig"
    local _cmd="apt update --print-uris 2> /dev/null | grep http | tr -d \' > $_fpath"
    if is_alive $_node; then
        ssh -t $UID_OFFLINE@$_node "$_cmd"
        if [ $? -eq 0 ]; then
            scp $UID_OFFLINE@$_node:"$_fpath" "$_DIR_UPDATES"
        else
            printf "${RED}An error occurred while running the update command for %s.{$RST}\n\n" $_node
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
    # Create the /tmp/updates directory, if it does not exist.
    [ ! -d $_DIR_UPDATES ] && mkdir $_DIR_UPDATES
    printf "Removing any old .sig files in %s ...\n" $_DIR_UPDATES
    rm $_DIR_UPDATES/*.sig > /dev/null 2>&1
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


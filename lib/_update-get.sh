#!/usr/bin/env bash
#-------------------------------------------------------------------------
# Script:   update-get
# Desc:     This script contains the functionality for acp's update/get
#           routine.
#
#           This script is designed to download all package meta-files
#           from the URLs listed in each .sig file. This operation occurs
#           for each .sig file in the provided .tar archive.
#
#           Next steps:
#           Use the --update --install PATH arguments to install the 
#           downloaded files into each offline target host's 
#            /var/lib/apt/lists directory.
#
# Usage:    $ acp --update --get path/to/update_<datetime>.tar
#
# Updates:
# 11-07-24  J. Berendt  Written. Logic based on the cstmgt-update-get
#                       script.
#-------------------------------------------------------------------------

# Read config file and supporting functionality.
_dir="$( dirname "$( realpath "$0" )" )" 
. "$_dir/.config"
. "$_dir/utils.sh"

# Constants
_DIR_UPDATES="/tmp/updates-get"
_DIR_UPDATES_DL="/tmp/updates-get/download"

#
# Pack all of the *.tar files (containing the downloaded package metadata
# files) into a single archive, for transport back to the offline system.
#
# @return Returns the exit code from the tar command if successful,
#         otherwise 1 is returned.
#
function archive() {
    local _base=$( basename $_INPATH )
    local _excode=
    local _outfile="$HOME/Desktop/${_base%%.*}.tar"
    printf "\nArchiving the package metadata *.tar files ...\n"
    pushd $_DIR_UPDATES > /dev/null  # Hack tar to get the desired dir structure.
    tar -cf "${_outfile}" *.tar
    _excode=$?
    popd > /dev/null
    [ $_excode -ne 0 ] && exit 1  # Exit early if tar fails.
    printf "Done.\n\n"
    printf "${GRN}The downloaded package metadata files are ready for transport back to the offline\n"
    printf "system, and located here:\n"
    printf "\t- %s${RST}\n" "$_outfile"
    return $_excode
}

#
# Download all URIs contained in the first field of the provided input
# file, and store the downloaded file using the filename specified by the
# second field in the file.
#
# @param $1 Input to be read. This file should be generated using the 
#        'apt update --print-uris' command.
#
# @return Returns the exit code from the file reading loop.
#
function download() {
    local _bname=
    local _ext=
    local _infile="$1"
    rm "$_DIR_UPDATES_DL/*" > /dev/null 2>&1
    while IFS=' ' read url fname _; do
        _bname=$( basename $url )
        _ext=${_bname##*.}
        wget "$url" -O "${_DIR_UPDATES_DL}/${fname}.${_ext}"
    done < $_infile
    return $?
}

#
# Display the epilog message, instructing the user of the next step in the
# process.
#
function epilog() {
cat << EOF

Next steps:
    Copy the update_<datetime>.tar file, from the location mentioned
    above, to the offline system and run:

        $ acp --update --install path/to/update_<datetime>.tar

EOF
}

#
# Pack the downloaded package metadata files into an archive.
#
# @param $1 Full path to the .sig input file
#
# @return Returns the exit code from the tar command.
#
function pack() {
    local _infile="$1"
    local _fname=${_infile%%.*}  # Remove file ext to keep same fname for tar.
    tar -cf "${_fname}.tar" $_DIR_UPDATES_DL/*
    return $?
}

#
# Process each .sig file.
#
# For each .sig file unpacked from the archive, the package metadata is
# downloaded, using the URL(s) in the .sig file.
#
function process_sig_files() {
    printf "Processing the .sig files ...\n"
    for f in $_DIR_UPDATES/*.sig; do
        download "$f"
        pack "$f"  # No error check as packing needs to occur, even if the
                   # last download fails.
    done
    [ $? -eq 0 ] && archive
    return $?
}

#
# Pre-run setup operations.
#
# @return Always return 0.
#
function setup() {
    echo
    # Create the /tmp/updates-get/* directories, if they don't exist.
    [ ! -d $_DIR_UPDATES ] && mkdir $_DIR_UPDATES
    [ ! -d $_DIR_UPDATES_DL ] && mkdir $_DIR_UPDATES_DL
    printf "Removing old files in %s ...\n" $_DIR_UPDATES
    rm $_DIR_UPDATES/* > /dev/null 2>&1
    rm $_DIR_UPDATES_DL/* > /dev/null 2>&1
    printf "Done.\n\n"
    return 0
}

#
# Unpack the provided archive containing the .sig files into the defined
# /tmp directory.
#
# @return Returns the exit code from the tar command.
#
function unpack_archive() {
    tar -xvf "$_INPATH" -C $_DIR_UPDATES/ > /dev/null 2>&1
    return $?
}

#
# Entry-point and primary controller for the program.
#
function main() {
    local _excode=
    setup
    [ $? -eq 0 ] && unpack_archive
    [ $? -eq 0 ] && process_sig_files
    _excode=$?  # Store archive's exit code as the next call will overwrite.
    [ $_excode -eq 0 ] && epilog
    return $_excode
}

# Store command line arguments.
_INPATH="$1"  # Path to the archive containing the .sig files.

main


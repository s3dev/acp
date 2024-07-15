#!/usr/bin/env bash
#-------------------------------------------------------------------------
# Script:   upgrade-get
# Desc:     This script contains the functionality for acp's upgrade/get
#           routine.
#
#           This script is designed to download the latest package, for
#           all packages due for upgrade, from the URIs listed in each
#           .sig file. This operation occurs for each .sig file in the 
#           provided .tar archive.
#
#           Next steps:
#           Use the --upgrade --install PATH arguments to install the 
#           upgrades on each offline target host.
#
# Usage:    $ acp --upgrade --get path/to/upgrade_<datetime>.tar
#
# Updates:
# 16-07-24  J. Berendt  Written.
#-------------------------------------------------------------------------

# Read config file and supporting functionality.
_dir="$( dirname "$( realpath "$0" )" )" 
. "$_dir/.config"
. "$_dir/utils.sh"

# Constants
_DIR_UPGRADES="/tmp/upgrades-get"
_DIR_UPGRADES_DL="/tmp/upgrades-get/download"

#
# Pack all of the *.tar files (containing the downloaded package files)
# into a single archive, for transport back to the offline system.
#
# @return Returns the exit code from the tar command if successful,
#         otherwise 1 is returned.
#
function archive() {
    local _base=$( basename $_INPATH )
    local _excode=
    local _outfile="$HOME/Desktop/${_base%%.*}.tar"
    printf "\nArchiving the latest package files ...\n"
    pushd $_DIR_UPGRADES > /dev/null  # Hack tar to get the desired dir structure.
    tar -cf "${_outfile}" *.tar
    _excode=$?
    popd > /dev/null
    [ $_excode -ne 0 ] && exit 1  # Exit early if tar fails.
    printf "Done.\n\n"
    printf "${GRN}The latest packages have been downloaded and are ready for transport back to the offline\n"
    printf "system, and located here:\n"
    printf "\t- %s${RST}\n" "$_outfile"
    return $_excode
}

#
# Download the latest version of each package, using the URIs contained
# in the first field of the provided input file, and store the downloaded
# file using the filename specified by the second field in the file.
#
# As each package is downloaded, its MD5 checksum is compared against the
# checksum value listed in the .sig file. If the checksum does not match,
# a counter is incremented, with all mis-matches being reported at the 
# end.
#
# @param $1 Input to be read. This file should be generated using the 
#        'apt upgrade --print-uris' command.
#
# @return Returns the exit code from the file reading loop.
#
function download() {
    local _infile="$1"
    local _mismatch=0
    local declare -a _mismatches=()
    rm "$_DIR_UPGRADES_DL/*" > /dev/null 2>&1
    while IFS=' ' read url fname _ md5; do
        wget "$url" -O "${_DIR_UPGRADES_DL}/${fname}"
        if [ "$( md5sum ${_DIR_UPGRADES_DL}/${fname} | cut -d' ' -f1 )" != "$( echo $md5 | cut -d: -f2 )" ]; then
            ((_mismatch++))
            _mismatches+=($fname)
        fi
    done < ${_infile}
    # Test if any MD5 mismatches were found. If yes, report them.
    if [[ $_mismatch > 0 ]]; then
        printf "\nMismatches checksums (%d):\n" $_mismatch
        for i in ${_mismatches[@]}; do
            printf " - %s\n" "$i"
        done
        printf "\nChecksum verification result: ${RED}FAIL${RST}\n"
        return 1
    else
        printf "\n${GRN}Checksum verification result: PASS${RST}\n"
        return 0
    fi
}

#
# Display the epilog message, instructing the user of the next step in the
# process.
#
function epilog() {
cat << EOF

Next steps:
    Copy the appropriate upgrade_<datetime>.tar file, from the location mentioned
    above, to the offline system and run:

        $ acp --upgrade --install path/to/upgrade_<datetime>.tar

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
    local _excode=
    local _infile="$1"
    local _fname=${_infile%%.*}  # Remove file ext to keep same fname for tar.
    pushd $_DIR_UPGRADES_DL > /dev/null  # Hack tar to get a flat file structure.
    tar -cf "${_fname}.tar" *
    _excode=$?
    popd > /dev/null
    return $_excode
}

#
# Process each .sig file.
#
# For each .sig file unpacked from the archive, the latest package is
# downloaded, using the URI(s) in the .sig file.
#
function process_sig_files() {
    printf "Processing the .sig files ...\n"
    for f in $_DIR_UPGRADES/*.sig; do
        download "$f"
        pack "$f"  # No error check as packing needs to occur, even if the
                   # last download fails.
    done
    return $?
}

#
# Pre-run setup operations.
#
# @return Always return 0.
#
function setup() {
    echo
    # Create the /tmp/upgrades-get/* directories, if they don't exist.
    [ ! -d $_DIR_UPGRADES ] && mkdir $_DIR_UPGRADES
    [ ! -d $_DIR_UPGRADES_DL ] && mkdir $_DIR_UPGRADES_DL
    printf "Removing old files in %s ...\n" $_DIR_UPGRADES
    rm $_DIR_UPGRADES/* > /dev/null 2>&1
    rm $_DIR_UPGRADES_DL/* > /dev/null 2>&1
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
    tar -xvf "$_INPATH" -C $_DIR_UPGRADES/ > /dev/null 2>&1
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
    [ $? -eq 0 ] && archive
    _excode=$?  # Store archive's exit code as the next call will overwrite.
    [ $_excode -eq 0 ] && epilog
    return $_excode
}

# Store command line arguments.
_INPATH="$1"  # Path to the archive containing the .sig files.

main


#!/usr/bin/env bash
#-------------------------------------------------------------------------
# Prog:     acp
# Version:  0.1.0
# Desc:     Offline Debian (apt) package updater.
#
#           The acp program wraps the built-in apt program and is designed
#           to update an offline PC, or PC cluster.
#
# Use:      The program takes six forms: a find, get and install for 
#           both the update and upgrade processes. The find and install
#           jobs are run on the *offline* (target) environment, and the
#           get (or download) job is run on an *online* environment.
#
#           The first step is to update the local apt repository/database,
#           and is carried out using the '--update' argument, as follows:
#
#           1) *Find* the URLs where the package metadata can be obtained:
#               $ acp --update --find
#
#           2) *Get* (download) the package metadata from the internet:
#               $ acp --update --get PATH
#
#           3) *Install* the latest package metadata files:
#               $ acp --update --install PATH
#
#           The second step is to download the relevant updates and install
#           then on the offline environment and is carried out using the 
#           '--upgrade' argument, as follows:
#
#           4) *Find* the packages which need to be updated, using the
#               latest poackage metadata downloaded in step 2:
#               $ acp --upgrade --find
#
#           5) *Get* (download) the package updates from the internet:
#               $ acp --upgrade --get PATH
#
#           6) *Install* the latest updates:
#               $ acp --upgrade --install PATH
#
# Updates:
# 12-07-24  J. Berendt  Written. Based (in principal) on the apt-offline 
#                       program, which is now sparsely maintained and
#                       fiddly to work with.
#-------------------------------------------------------------------------

# Set current directory.
_dir="$( dirname "$( realpath "$0" )" )"
. "$_dir/.version"

# Initialise arguments.
arg_find=0
arg_get=0
arg_get_file=
arg_install=0
arg_install_file=
arg_update=0
arg_upgrade=0

#
# Program argument parser.
#
# @param $@ All command line parameters.
#
function argparser() {
    # Handle the -h | --help arguments.
    [[ "$1" == *"-h"* ]] && usage && exit 0
    # Verify number of arguments.
    [[ $# -lt 2 ]] && usage && printf "\n[ERROR]: Expected (at least) 2 arguments. See usage.\n\n" && exit 1
    # Parse arguments.
    while [[ "$#" -gt 0 ]]; do
        case $1 in
            -f|--find) arg_find=1; shift ;;
            -g|--get) arg_get=1; arg_get_file="$2"; shift 2 ;;
            -i|--install) arg_install=1; arg_install_file="$2"; shift 2 ;;
            -h|--help) usage; exit 0 ;;
            --update) arg_update=1; shift ;;
            --upgrade) arg_upgrade=1; shift ;;
            *) usage; printf "\n[ERROR]: Unknown argument (%s). See usage.\n\n" $1; exit 1 ;;
        esac
    done
    # Verify arguments are logical.
    if [[ $(($arg_update + $arg_upgrade)) -ne 1 ]]; then
        usage
        printf "\n[ERROR]: Only one of --update or --upgrade may be supplied. See usage.\n\n"
        exit 1
    fi
}

#
# Processing router.
#
# Route the program to the desired script, based on the parsed command 
# line arguments.
#
function router() {
    # The if/elif structure is used to preserve the child script's exit code.
    if [[ $(($arg_update + $arg_find)) -eq 2 ]]; then       "$_dir/_update-find.sh"
    elif [[ $(($arg_update + $arg_get)) -eq 2 ]]; then      "$_dir/_update-get.sh" "$arg_get_file"
    elif [[ $(($arg_update + $arg_install)) -eq 2 ]]; then  "$_dir/_update-install.sh" "$arg_install_file"
    elif [[ $(($arg_upgrade + $arg_find)) -eq 2 ]]; then    "$_dir/_upgrade-find.sh"
    elif [[ $(($arg_upgrade + $arg_get)) -eq 2 ]]; then     "$_dir/_upgrade-get.sh" "$arg_get_file"
    elif [[ $(($arg_upgrade + $arg_install)) -eq 2 ]]; then "$_dir/_upgrade-install.sh" "$arg_install_file"
    fi
}

#
# Print program usage statement.
#
function usage() {
cat << EOF

Perform an offline PC or cluster update.

Note: This process requires an online PC to be available which is used to
      download the relevant updates from the internet.

      The downloaded files are then transferred to the offline system for
      installation.

Usage: acp ROUTINE TASK [PATH]

Routine arguments:

    Choose *one* of the following.

    --update    The first routine in the series of tasks.
                Performs 'apt update' related tasks, such as updating the 
                internal apt repository in preparation for an upgrade.
    --upgrade   The second routine in the series of tasks.
                Performs 'apt upgrade' related tasks, such as downloading
                and installing the relevant updates.

Task arguments:

    Choose *one* of the following.

    -f, --find      First task for each routine.
                    Find the package metadata URL(s) or package URL(s) 
                    which are to be downloaded.
    -g, --get       Second task for each routine.
                    Get (download) the listed package metadata files or 
                    packages for upgrade. This task must be performed on
                    an ** internet connected  ** PC.
                    This argument requires a PATH to the target .tar 
                    archive containing the package metadata to be 
                    retrieved.
    -i, --install   Third task for each routine.
                    Install the downloaded package metadata files 
                    (for the --update routine), or install the downloaded
                    updates (for the --upgrade routine).
                    This argument requires a PATH to the target .tar 
                    archive containing the package metadata to be 
                    installed.

Examples:

    The first series of steps is to update the local apt repository/database,
    and is carried out using the '--update' argument, as follows:

    1) *Find* the URLs where the package metadata can be obtained:
        $ acp --update --find

    2) *Get* (download) the package metadata from the internet:
        $ acp --update --get PATH

    3) *Install* the latest package metadata files:
        $ acp --update --install PATH

    The second step is to download the relevant updates and install
    then on the offline environment and is carried out using the 
    '--upgrade' argument, as follows:

    4) *Find* the packages which need to be updated, using the
        latest package metadata downloaded in step 2:
        $ acp --upgrade --find

    5) *Get* (download) the latest package(s) from the internet:
        $ acp --upgrade --get PATH

    6) *Install* the latest updates:
        $ acp --upgrade --install PATH

acp v${VERSION}

EOF
    return 0
}

#
# Main program controller and entry-point.
#
# @param $@ All command line parameters.
#
function main() {
    argparser "$@"
    router
    return $?
}

main "$@"


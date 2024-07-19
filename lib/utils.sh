#!/usr/bin/env bash
#-------------------------------------------------------------------------
# Prog:     utils.sh
# Desc:     Generalised utilities used by the acp project.
#
# Updates:
# 15-07-24  J. Berendt  Written. Adapted from libsh.
#-------------------------------------------------------------------------

# Terminal colour definitions.
BLU='\033[34m'
CYN='\033[36m'
GRN='\033[32m'
MAG='\033[35m'
RED='\033[31m'
RST='\033[0m'
WHT='\033[37m'
YLW='\033[33m'

#
# Verify if the host is alive.
# 
# @param[in] $1 Hostname or IP address to be tested.
# @return       0, if the host is alive, otherwise 1. 
#               This enables an if is_alive test by the caller. 
#               Reference: if(1)
#
function is_alive() {
    ping -c1 -W1 "$1" &> /dev/null
    [ $? -eq 0 ] && return 0 || return 1
}

#
# Test if all nodes in the provided array are alive.
#
# @param[in] $1 An array containing all nodes to be tested.
#
# @return       0, if all nodes in the array are alive, otherwise 1.
#
function is_alive_all() {
    status=0
    for node in $@; do
        printf "%s -- " $node
        if ( ! is_alive $node ); then
            printf "${RED}down${RST}\n"
            status=1
        else
            printf "${GRN}up${RST}\n"
        fi
    done
    return $status
}

#
# Verify all nodes are alive.
#
# @return   0, if all nodes are alive, otherwise 1.
#
function is_alive_all_nodes() {
    printf "\n${CYN}Status of all nodes:${RST}\n"
    is_alive_all ${hostnames[@]}
    [ $? -eq 0 ] && return 0 || return 1
}

#
# Verify all *worker* nodes are alive.
#
# @return   0, if all worker nodes are alive, otherwise 1.
#
function is_alive_all_workers() {
    printf "\n${CYN}Status of all worker nodes:${RST}\n"
    is_alive_all ${hostnames_workers[@]}
    [ $? -eq 0 ] && return 0 || return 1
}

# Verify if the host is online (internet connected).
# 
# @return   0, if the host is online, otherwise 1. 
#           This enables an if is_online test by the caller.
#           Reference: if(1)
#
function is_online() {
    ping -c1 -W1 8.8.8.8 &> /dev/null
    [ $? -eq 0 ] && return 0 || return 1
}

#!/usr/bin/env bash
#-------------------------------------------------------------------------
# Prog:     colours
# Version:  0.1.0
# Desc:     A simple config file providing ANSI escape sequences for 
#           terminal text colouring.
#
# Use:      From a shell script:
#
#               # Source external config files.
#               . /mnt/core/etc/colours
#
# Updates:
# 19-10-23  J. Berendt  Written
#-------------------------------------------------------------------------


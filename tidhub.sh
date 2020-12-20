#!/bin/bash

########################################
### Global constats/variables
########################################

rcfile=~/.config/tidhub/tidhubrc
rctempl="# This file is to be sourced from tidhub.sh

declare -A wiki # do NOT change this

# User wiki array definition wiki[key]=value:
# Key is the unique user defined identifier of the wiki instance
# Value is the path to the wiki instance dir
wiki[hnts]=~/Notes/home_notes/
wiki[wnts]=~/Notes/work_notes/
wiki[train]=~/Training/my_journal/
wiki[3]=~/Todo/"


########################################
### Functions definition
########################################


########################################
# Check existence of rcfile and
# create it from the template if doesn't exist
#
# Globals:
#   rcfile used
#   rctempl used
#
# Arguments
#   none
#
# Outputs:
#		STDOUT message about creating rcfile
#   rcfile create it if does not exist
#
# Returns:
#   none
########################################
check_rc () {
	local rcdir="${rcfile%/*}"
	if [[ ! -r "${rcfile}" ]]; then
		[[ -d "${rcdir}" ]] || mkdir "${rcdir}" # mkdir if necessary
		echo "Required config file $rcfile is missing, so I'm creating it."
		echo -e "You should edit it to reflect your own wikis placement.\n"
		echo "$rctempl" > "${rcfile}"
	fi
}
########################################

########################################
# Print tidhub usage
########################################
usage (){

cat << _EOF_
Purpose: Manage multiple Node.js' Tiddlywikis from this hub

Usage:
  tidhub.sh [option [argument]]

Options and their argument:
  [-h|--help]           print this document (default)
  [-l|--list]           list all available wikis with a R flag if running
  [-r|--run]  [keylist] run all wikis (default) or just those in the keylist
  [-s|--stop] [keylist] stop all running wikis (default) or just those in the keylist
  keylist               is a list of keys in 'wiki' array
                        defined in 'tidhubrc' file (details see below)

Usage examples:
  tidhub -l          list wikis: key, pid, port
  tidhub -r hnts 3   run wikis identified by the key 'hnts' and '3'
  tidhub -s 3        stop wiki identified by the key '3'

Config file '${rcfile##*/}':
  Tidhub makes use of '~/${rcfile#/*/*/}' file.
  If it does'not exist it will be automatically created from the template.
  You have to edit it to reflect your own wikis placement.
  It declares bash associative array of key=values pair,
  where 'key' is the unique identifier (shorcut) of the wiki and
        'value' is the path to it.

Example (template) of '${rcfile##*/}' file content:
--------------------------------------
${rctempl}
--------------------------------------

Requirements:
  External programs required: Tiddlywiki on Node.js, awk, pgrep, pkill
_EOF_
}
########################################

########################################
# List status of configured wikis: key pid port
#
# Globals:
#   wiki used
#
# Arguments
#   none
#
# Outputs:
#   list of wikis: key pid port
#
# Returns:
#   none
########################################
list_wikis () {
	echo "listing"
}
########################################

########################################
# Run all/selected wikis
#
# Globals:
#   wiki used
#
# Arguments
#   [keylist] of wikis to run, default is all
#
# Outputs:
#   input
#
# Returns:
#   none
########################################
run_wikis () {
	echo "run: $@"
}
########################################

########################################
# Stop all/selected wikis
#
# Globals:
#   wiki used
#
# Arguments
#   [keylist] of wikis to stop, default is all
#
# Outputs:
#   none
#
# Returns:
#   none
########################################
stop_wikis () {
	echo "stop: $@"
}
########################################


########################################
### Main
########################################
# Prepare
check_rc
source "$rcfile"
# Read opts and run service functions accordingly
case $1 in
	-h | --help)
		 usage
		;;
	-l | --list)
		list_wikis
		;;
	-r | --run)
		shift
		run_wikis $@
		;;
	-s | --stop) #
		shift
		stop_wikis $@
		;;
	*)
		[[ -z $1 ]] || echo -e "Unregognized input '$1'\n" >&2 && usage
		;;
esac
exit
########################################


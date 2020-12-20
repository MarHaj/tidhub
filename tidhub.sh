#!/bin/bash

########################################
### Global constats/variables
########################################

rcfile=~/.config/tidhub/tidhubrc
rctempl="# This file is to be sourced from tidhub.sh

declare -A tiddirs # do NOT change this

# User tiddirs array definition:
# Index is the unique user defined identifier (key) of the wiki instance
# Value is the path to the wiki instance dir
tiddirs[hnts]=~/Notes/home_notes/
tiddirs[wnts]=~/Notes/work_notes/
tiddirs[train]=~/Training/my_journal/
tiddirs[3]=~/Todo/
"


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
		echo "You should edit it to reflect your own wikis placement."
		echo "$rctempl" > "${rcfile}"
	fi
}
########################################

########################################
# Print tidhub usage
########################################
usage (){

cat << _EOF_
Manage multiple Node.js' Tiddlywikis from this hub

Usage:
  tidhub.sh [option [argument]]

Options and their argument:
  [-h|--help]           print this document (default)
  [-l|--list]           list all available wikis with a R flag if running
  [-r|--run]  a|keylist run all wikis or just this keylist (default first from list)
  [-s|--stop] a|keylist stop all running wikis (default) or just this keylist
  keylist               is a list of keys indexes in 'tiddirs' array
                        which is defined in 'tidhubrc' file (see below)

Usage examples:
  tidhub -l          list wikis
  tidhub -r hnts 3   run wiki identified by the key 'hnts' and 3
  tidhub -s 3        stop wiki identified by the key 3

Config file '${rcfile##*/}':
  Tidhub makes use of '~/${rcfile#/*/*/}' file that must exist and be readable.
  It declares bash associative array of key=values pair,
  where 'key' is the unique identifier (name) of the wiki and
        'value' is the path to it.

Example of '${rcfile##*/}' file content:
--------------------------------------
${rctempl}
--------------------------------------

Requirements:
  External programs required: Tiddlywiki on Node.js, awk, pgrep, pkill
_EOF_
}
########################################

########################################
# List wikis and mark Running ones
#
# Globals:
#   tiddirs used
#
# Arguments
#   none
#
# Outputs:
#   list of wikis: key pid port R-flag
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
#   tiddirs used
#
# Arguments
#   [a|keylist] wikis to run
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
#   tiddirs used
#
# Arguments
#   [a|keylist] wikis to stop
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


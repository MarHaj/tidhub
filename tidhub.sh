#!/bin/bash

########################################
### Functions definition
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
  keylist
		is a list of keys indexes in 'tiddirs' array as defined in 'tidhubrc' file (see below)

Usage examples:
  tidhub -l          list wikis
  tidhub -r hnts 3   run wiki identified by key 'hnts' and 3
  tidhub -s 3        stop wiki identified by key 3

Config file tidhubrc:
  Tidhub makes use of ~./config/tidhub/tidhubrc file that must exist and be readable.
  It declares bash associative array of key=values pair,
	where key is an unique identifier (name) of the wiki and value is path to it.

Example of tidhubrc file:

# This file is to be sourced from tidhub.sh
declare -A tiddirs
# Index of tiddirs is the unique user defined identifier (key) of the wiki instance
# Value of tiddirs is the path to the wiki instance
#
# User definitions:
tiddirs[hnts]="~/Notes/home_notes/"
tiddirs[wnts]="~/Notes/work_notes/"
tiddirs[train]="~/Training/my_journal/"
tidddirs[3]="~/Todo/"

Requirements:
  External programs required:
	  Tiddlywiki on Node.js, awk, pgrep, pkill
_EOF_
		exit
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
# Get program options and args from positional parameters
# calling: get_opt_arg $@
########################################
get_opt_arg () {
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
}
########################################

# Tests
get_opt_arg $@

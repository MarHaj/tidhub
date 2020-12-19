#!/bin/bash

usage (){

cat << _EOF_
Manage multiple Node.js' Tiddlywikis from this hub

Usage:
  tidhub [option [argument]]

Options and their argument:
  [-h|--help]  print this document and exit (default)
  [-l|--list]  list all available wikis with a R flag if running
  [-r|--run]   a|# run all wikis or just this # (default from config file)
  [-s|--stop]  a|# stop all running wikis (default) or just this #

Usage examples:
  tidhub -l       list wikis
  tidhub -r 1 3   run wiki 1 and 3
  tidhub -s 1     stop wiki 1

Config file tidhubrc:
  Tidhub makes use of ~./config/tidhub/tidhubrc file that must exist and be readable.
  It declares bash array of absolute paths to tiddliwiki directories.
  Example of tidhubrc file:

# some comment
# and another one
tiddirs=(
"~/Notes/home_notes/"
"~/Notes/work_notes/"
"~/Training/my_journal/"
)
_EOF_
		exit
}

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
			echo "list"
			;;
		-r | --run)
			echo "run"
			# now read $2 arguments
			;;
		-s | --stop)
			echo "stop"
			# now read $2 arguments
			;;
		*)
			echo "Unregognized '$1' input." >&2
			usage
			;;
	esac
}
########################################

# Tests
get_opt_arg $@

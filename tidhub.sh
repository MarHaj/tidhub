#!/bin/bash

########################################
### Global constats/variables
########################################

rcfile=~/.config/tidhub/tidhubrc
rctempl="# This file is sourced from tidhub.sh

declare -A wiki # DO NOT CHANGE THIS

# User wiki array definition: wiki[key]=value:
# Key is the unique user defined identifier of user's wiki instance
# Value is the path to the wiki instance — directory, where the file
# 'tiddlywiki.info' is.
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
# Outputs:
#   STDOUT: message about creating rcfile
#   rcfile: file - create it if does not exist
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
# Print TidHub usage
########################################
print_usage (){

cat << _EOF_
Purpose: Manage multiple Node.js' Tiddlywikis from this hub

Usage:
  There are two modes of usage, Informative and Executive.

  Informative mode of usage: tidhub.sh [option]
    Options:
      [-h|--help]           print this document default, i.e. when no option or
                            command is provided)
      [-s|--status]         print info about configured and running wikis
      [-v|--version]        print program version

  Executive mode of usage: tidhub command [keylist]
    Commands:
      run                   run wikis according keylist option provided
      stop                  stop wikis according keylist option provided
    Options:
      [keylist]             list of wiki keys (see below) separated by space.
                            If no keylist id provided, then command will be
                            executed on all configured or running wikis

  Usage examples:
    tidhub -s               list wikis: key, path, pid, port
    tidhub -r hnts 3        run wikis identified by the key 'hnts' and '3'
    tidhub -s 3             stop wiki identified by the key '3'

Configuration
    TidHub makes use of '~/${rcfile#/*/*/}' file, where you have to configure
    your specific wikis setup.
    If the file does'not exist it will be automatically created from the template.
    You have to edit it to reflect your own wikis specifications.
    How to do it can be found directly in the file itself.
    See the template/example below:
--------------------------------------
${rctempl}
--------------------------------------

Requirements:
  External programs required by TidHub:
    Tiddlywiki on Node.js, awk, sed, pgrep, pkill
_EOF_
}
########################################

########################################
# Print status of configured wikis: key pid port
#
# Globals:
#   wiki array used
#   rcfile configuration file
#
# Outputs:
#   STDOUT status of wikis: key path pid port
########################################
print_status () {
  echo "Printing status"
}
########################################

########################################
# Print TidHub version
#
# Globals:
#   wiki used
#
# Outputs:
#   STDOUT TidHub version info
########################################
print_version () {
  echo "Printing version"
}
########################################

########################################
# Run all/selected wikis
#
# Globals:
#   wiki used
#   rcfile config file
#
# Arguments
#   [keylist] of wikis to run, default is all
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
#   rcfile config file
#
# Arguments
#   [keylist] of wikis to stop, default is all
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
     print_usage
    ;;
  -s | --status)
    print_status
    ;;
  -v | version)
    print_version
    ;;
  run)
    shift
    run_wikis $@
    ;;
  stop)
    shift
    stop_wikis $@
    ;;
  *)
    [[ -z $1 ]] || echo -e "Unregognized input '$1'\n" >&2 && print_usage
    ;;
esac
exit
########################################


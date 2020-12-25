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
#   STDERR: if rcfile missing
#   STDERR: if unrecognised user input
#   STDERR: if unable to create rcfile
#   rcfile: if user interractively agrees about creating this file (incl dir)
#
# Returns:
#   exit 0: user responds not to create file by tidhub
#   exit 1: unable to create rcfile
#   exit 2: unregognised user input
########################################
check_rc () {
  local rcdir="${rcfile%/*}"
  if [[ ! -r "${rcfile}" ]]; then
    echo "Required config file '$rcfile' is missing." >&2
    read -n 1 -p "Can I create it? Reply: y|n > "
    echo ""
    if [[ $REPLY == n ]]; then
      echo -e "\nYou should create '$rcfile' by yourself. It's required by tidhub."
      exit 0
    elif [[ $REPLY == y ]]; then
      [[ -d "${rcdir}" ]] || mkdir "$rcdir" && echo "$rctempl" > "$rcfile"
      if [[ -r "${rcfile}" ]]; then
        echo -e "\nFile '$rcfile' successfully created."
        echo "You should edit it to reflect your own wikis placement."
      else
        echo -e "\nUnable to create '$rcfile'. Something is wrong." >&2
        exit 2
      fi
    else
      echo -e "\nAnswer unregognized." >&2
      exit 2
    fi
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
# Make CSV config list from wiki array
#
# Globals:
#   wiki: array used
#
# Outputs:
#   STDOUT: CSV list of configured wiki: key,path,,
########################################
conf2csv () {
  local i
  for i in ${!wiki[@]}; do
    echo "$i,"${wiki[$i]}",,"
  done
}
########################################

########################################
# Make CSV list of live wikis
# using output from command 'pgrep - a node'
# Filter ouput only to items where command line containing 'tiddlywiki' word
#
# Outputs:
#   STDOUT: CSV list of running wikis: ,path,pid,port
#
# Requires:
#   EXT: pgrep, awk, sed
########################################
live2csv () {
# output from $(pgrep -a node)
  pgrep -a node | \
    awk '/tiddlywiki/ { print ","$4","$1","$6 }' | \
    sed 's/port=//'
}
########################################

########################################
# Merge conf and live CSV lists
# Merging based on common field "path to wiki"
#
# Outputs:
#   STDOUT: csv status list: key,path,pid,port
#
# Requires:
#   INT: conf2csv, live2csv
########################################
status_csv () {
  local live_line
  local conf_line
  local output_line=""

  while IFS=, read -r -a conf_line; do # loop config
    output_line=$(printf '%s,%s,%s,%s\n' "${conf_line[@]}")
    while IFS=, read -r -a live_line; do # loop live
      if [[ "${conf_line[1]}" = "${live_line[1]}" ]]; then # merge lines
        output_line="${conf_line[0]},${conf_line[1]},${live_line[2]},${live_line[3]}"
        live_list=$(echo "$live_list" | \
                    sed "/${live_line[3]}/d") # remove this line from live_list
        break # no need to continue inner loop
      fi
    done <<< "$(live2csv)"
    echo "$output_line"
  done <<< "$(conf2csv)"
  echo "$live_list" # remaning live_list
}
########################################

########################################
# Prints formatted & verified status of configured an live wikis with a header line
# Verification, that every path points to a direcory containing 'tiddlywiki.info'
#
# Outputs:
#   STDOUT: formatted list key,path,pid,port
#
# Requires:
#   EXT: sed, awk
#   INT: status_csv
########################################
print_status () {
  local line
  local stat=""
  local header="KEY,PATH,PID,PORT\n"
  local footer="W.N.A: Wiki Not Avalilable on the path specified"
  wna_flag="false"
  local mx=4

# if path does not point to tiddlywiki.info then replace it by 'w.n.a.'
# also shorten path to ~/something nicely
# also determine max length path mx

  while IFS=, read -r -a line; do
    if [[ -f "${line[1]}tiddlywiki.info" ]]; then
      line[1]="~/${line[1]#/*/*/}"
    else
      line[1]="w.n.a."
      flag=true
    fi
    (( mx < ${#line[1]} )) && mx=${#line[1]}
    stat+="${line[0]},${line[1]},${line[2]},${line[3]}\n"
  done <<< $(status_csv)

# final output
  mx=$(( $mx + 2 ))
  echo -e "-------\n${header}${stat}" | \
    awk -F, '{ printf "%-7s %-'${mx}'s %-6s %-6s \n", $1, $2, $3, $4 }' | \
    sed '$d'
  echo "-------"
  [[ $flag ]] && echo -e "$footer"
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


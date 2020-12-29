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
wiki_status_csv="" # wiki status csv list


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
        echo -e  "\nFile '$rcfile' successfully created."
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
      [-s|--status]         print status info about configured and running wikis
      [-v|--version]        print program version

  Executive mode of usage: tidhub command [keylist]
    Commands:
      start                 start wikis according keylist option provided
      stop                  stop wikis according keylist option provided
    Options:
      [keylist]             list of wiki keys (see below) separated by space.
                            If no keylist id provided, then command will be
                            executed on all configured or running wikis

  Usage examples:
    tidhub -s               print status info about wikis
    tidhub start hnts 3     star wikis identified by the keys 'hnts' and '3'
    tidhub stop 3           stop wiki identified by the key '3'

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
merge_csv () {
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
# Create nice global wiki_status_csv list
# If config path does not point to tiddlywiki.info then replace it by 'WNA'.
# Also shorten path to ~/something nicely.
#
# Globals:
#   wiki_status_csv: changed
#
# Requires:
#   INT: merge_csv
########################################
mk_wiki_status () {
  local line
  wiki_status_csv=""

  while IFS=, read -r -a line; do
    if [[ -f "${line[1]}tiddlywiki.info" ]]; then
      line[1]="~/${line[1]#/*/*/}"
    else
      line[1]="WNA"
    fi
    # (( mx < ${#line[1]} )) && mx=${#line[1]} # TODO: remove this line
     echo "${line[0]},${line[1]},${line[2]},${line[3]}"
  done <<< $(merge_csv)
}

########################################
# Prints formatted wiki status
#
# Globals:
#   wiki_status_csv: used
#
# Outputs:
#   STDOUT: formatted list: key,path,pid,port + footer if WMA found
#
# Requires:
#   EXT: sed, awk, sort
########################################
print_status () {
  local header="KEY,PATH,PID,PORT\n"
  local footer="WNA: Wiki Not Avalilable on the path configured"
  local mxpl

# determine max path length for formatting purpose
  mxpl=$(echo "${wiki_status_csv}" | \
    awk -F, '{ print $2 }' | \
    awk '{ print length}' | \
    sort -nr | \
    sed '1!d'
  )
  (( $mxpl < 4 )) && mxpl=6 || mxpl=$(( $mxpl + 2 ))

# final output
  echo -e "-------\n${header}${wiki_status_csv}" | \
    awk -F, '{ printf "%-7s %-'${mxpl}'s %-6s %-6s \n", $1, $2, $3, $4 }'
  echo "-------"
  (( $(echo "$wiki_status_csv" | grep -E -c ',WNA,') )) && echo "$footer"
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
#   [keylist] of wikis to start, default is all
########################################
start_wikis () {
  echo "Start: $@"
}
########################################

########################################
# Stop all/selected wikis
#
# Globals:
#   wiki_status_csv: used
#
# Arguments:
#   [keylist]: space separated list of wikis key to stop, default is stop all
#
# Requires:
#   EXT: awk
########################################
stop_wikis () {
  local killed=0 # total killed count
  local arr # CSV line: key,path,pid,port
  local wpid # wiki pid to kill
  local wrunning="$(echo "$wiki_status_csv" | grep ',[0-9]\+$')" # running wikis only

  if [[ $# == 0 ]]; then # kill all running wikis, cycle through keys
    echo "Kill all"
    while IFS="," read -a arr; do
      wpid=${arr[2]}
      [[ -n "$wpid" ]] \
        && echo "Killing '${arr[0]}' pid $wpid" \
        && (( killed+=1 )) # TODO real kill
    done <<< "$wrunning" # running wikis only
  else # kill some, cycle through positional args - keys
    echo "Kill some"
    while (( $# > 0 )); do
      wpid=$(echo "$wrunning" | \
        awk -F, -v key="^$1\$" ' $1 ~ key { print $3 }') # find pid according key
      [[ -n "$wpid" ]] \
        && echo "Killing '$1' pid $wpid" \
        && (( killed+=1 )) # TODO real kill
# FIXME update wrunning/mk_wiki_status() after each kill
# otherwise multiple kills possible
    shift
    done
  fi
  echo "Killed total: $killed"
}
########################################


########################################
### Main
########################################
# Prepare
check_rc
source "$rcfile"
wiki_status_csv=$(mk_wiki_status)

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
  start)
    shift
    start_wikis "$@"
    ;;
  stop)
    shift
    stop_wikis "$@"
    ;;
  *)
    [[ -z $1 ]] || echo -e "Unregognized input '$1'\n" >&2 && print_usage
    ;;
esac
exit
########################################


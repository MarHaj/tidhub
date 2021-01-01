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
  local header="KEY,PATH,PID,PORT"
  local footer="WNA: Wiki Not Avalilable on the path configured"
  local mxpl # maximum of paths lengths

# determine max path length for formatting purpose
  mxpl=$(echo "${wiki_status_csv}" | \
    awk -F, '{ print $2 }' | \
    awk '{ print length}' | \
    sort -nr | \
    sed '1!d'
  )
  (( $mxpl < 4 )) && mxpl=6 || mxpl=$(( $mxpl + 2 ))

# final output
  echo -e "-------\n${header}\n${wiki_status_csv}" | \
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
# Find first free TCP port from defined range
#
# Globals:
#   wiki_status_csv: used
#
# Arguments:
#   $1: name of the array of tcp ports range
#   $2: name of the array with already listening tcp ports
#
# OUTPUTS:
#   STDOUT: free port or ""
#   STDERR: message if no free port found
#
# RETURNS:
#   return 0: success
#   exit 1: no free TCP port in the range
#
# Reguires:
#   EXT: ss, awk
########################################
get_free_port () {
  local -n range=$1 # referenced array of ports to select from
  local -n busy=$2  # referenced array of listening ports
  local i j

  for i in "${range[@]}"; do # loop through range tcp values
    found_flag="true"
    # echo "Testing tcp: ${range[$i]}"
    for j in "${busy[@]}"; do # loop through busy tcp values
      [[ $i -eq $j ]] && found_flag="false" && break
    done
    if [[ "$found_flag" == "true" ]]; then
      echo "$i"
      return 0 # on the first occurrence of free port
    fi
  done
  echo "No free TCP port has been found in range ${range[@]}" >&2
  exit 1 # cannot continue because no free port in the range has been found
}
########################################

########################################
# Start All/selected wikis
#
# Globals:
#   wiki_status_csv: used
#
# Arguments:
#   [keylist]: of wikis to run, default is all
#
# Requires:
#   INT: get_free_port
#   EXT: awk
########################################
start_wikis () {
  local tcp_range=( {8001..8010} ) # array of ports to select from
  local tcp_busy=( 8001 8002 8005 8006 )
#  local tcp_busy=( $(ss -tl \
#    | awk '/LISTEN/ { print $4 }' \
#    | awk -F: '$2 ~ /[0-9]+/ { print $2 }') ) # array of already listening ports
  local started=0 # total started count
  local line # line array
  local wport
  local key
  declare -A path_arr
  declare -A port_arr

# Make path_arr (key path) and port_arr (key port) for wikis available to start
  while IFS="," read -a line; do # array=( key path pid port )
    key=${line[0]}
    path_arr[$key]="${line[1]}"
    wport=$(get_free_port tcp_range tcp_busy)
    port_arr[$key]=$wport
    tcp_busy+=($wport) # after port assignment make it look like busy
  done <<< "$(echo "$wiki_status_csv" \
    | grep -v ',WNA,\|[0-9]\+$')" # wikis available to start (not WNA or running)
  [[ ${#port_arr[@]} -ne ${#path_arr[@]} ]] \
    && echo "Unexpected error" >&2 \
    && exit 1

# Start all wikis
  if [[ $# -eq 0 ]]; then
    echo "Start all"
    for key in ${!path_arr[@]}; do
      echo "Startinq wiki $key on '${path_arr[$key]}' and ${port_arr[$key]}"
      (( started+=1 ))
    done
  fi

# Start wikis according keys provided by CLI
  while (( $# > 0 )); do # args cycle
    echo "Start some"
    for key in ${!path_arr[@]}; do
      if [[ "$1" == "$key" ]]; then
        echo "Startinq wiki $key on '${path_arr[$key]}' and ${port_arr[$key]}"
        (( started+=1 ))
      fi
    done
    shift
  done
  echo "Started total: $started"
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
# Outputs:
#   STDOUT: total count of stopped wikis
########################################
stop_wikis () {
  local killed=0 # total killed count
  declare -A pids_arr # associative array of keys,pids of all running wikis
  local line
  local i

# Get pids_arr
  while IFS="," read -a line; do # line array=( key path pid port )
    [[ -n "${line[2]}" ]] && pids_arr[${line[0]}]=${line[2]}
  done <<< "$wiki_status_csv"

# Kill all wikis
  if [[ $# -eq 0 ]]; then
    for i in ${pids_arr[@]}; do
      kill $i || kill -9 $i \
        && (( killed+=1 ))
    done
  fi

# Kill wikis according keys provided by CLI
  while (( $# > 0 )); do # args cycle
    for i in ${!pids_arr[@]}; do
      if [[ "$1" == "$i" ]]; then
        kill ${pids_arr[$i]} || kill -9 ${pids_arr[$i]} \
          && unset pids_arr[$i] \
          && (( killed+=1 ))
      fi
    done
    shift
  done
  echo "Stopped total: $killed"
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
  -v | --version)
    print_version
    ;;
  start)
    shift
    start_wikis "$@"
    wiki_status_csv=$(mk_wiki_status)
    print_status
    ;;
  stop)
    shift
    stop_wikis "$@"
    wiki_status_csv=$(mk_wiki_status)
    print_status
    ;;
  *)
    [[ -z $1 ]] || echo -e "Unregognized input '$1'\n" >&2 && print_usage
    ;;
esac
exit
########################################


#!/bin/bash

########################################
### Global constats/variables
########################################

rcfile=~/.config/tidhub/tidhubrc
rctempl="# This file is sourced from tidhub.sh

declare -A WIKI # DO NOT CHANGE THIS

# User wiki associative array definition: WIKI[key]=value
# Key is the unique user defined identifier of user's wiki instance
# Value is the path to the wiki instance — i.e. to the directory,
# where 'tiddlywiki.info' file is at the top.
WIKI[hnts]=~/Notes/home_notes/
WIKI[wnts]=~/Notes/work_notes/
WIKI[train]=~/Training/my_journal/
WIKI[3]=~/Todo/"
wiki_status_csv="" # wiki status CSV list


########################################
### Functions definitions
########################################


########################################
# Print TidHub version
#
# Outputs:
#   STDOUT TidHub version info
########################################
print_version () {
  echo "Version 1.0.0, date 2021-01-03"
}
########################################

########################################
# Print short usage
########################################
print_usage () {
  cat << _EOF_
Usage: tidhub.sh [option] | [command] [keylist]
  Options: [-h|--help] | [-s|--status] | [-v|--version]
  Commands: start | stop | view
    Keylist: space separated wiki keys (see --help)
_EOF_
}
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
        exit 1
      fi
    else
      echo -e "\nAnswer unregognized." >&2
      exit 2
    fi
  fi
}
########################################

########################################
# Print detailed help
########################################
print_help (){

  cat << _EOF_
Purpose:
  Manage multiple local 'Tiddlywikis' on 'Node.js'

Usage:
  There are two modes of usage: Informative and Executive.

  Informative mode of usage: tidhub.sh [option]
    Options:
      [-h|--help]           print this document default, i.e. when no option or
                            command is provided)
      [-s|--status]         print status info about configured and running wikis
      [-v|--version]        print program version
      [ ]                   print short usage info

  Executive mode of usage: tidhub command [keylist]
    Commands:
      start                 start wikis
      stop                  stop wikis
      view                  view vikis in the default browser

      [keylist]             list of wiki keys (see below) separated by space.
                            If no keylist is provided, then command will be
                            executed on all configured wikis possible.

  Usage examples:
    tidhub -s               print status info about wikis
    tidhub start hnts 3     start wikis identified by the keys 'hnts' and '3'
    tidhub stop 3           stop wiki identified by the key '3'

Configuration:
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
    Tiddlywiki on Node.js, awk, sed, pgrep, ss,
    xdg-open|x-wwwbrowser|sensible-browser

Copyright notice:
    Copyright  2021 MarHaj at https://github.com/MarHaj/
    under GNU General Public Licence version 3 or later:
    https://www.gnu.org/licenses/gpl-3.0.txt

    This program comes with ABSOLUTELY NO WARRANTY.
    This is free software, and you are welcome to redistribute it
    under conditions of GNU GPL Licence.
_EOF_
}
########################################

########################################
# Make CSV config list from wiki array
#
# Globals:
#   WIKI: array used
#
# Outputs:
#   STDOUT: CSV list of configured wiki: key,path,,
########################################
conf2csv () {
  local i
  for i in ${!WIKI[@]}; do
    echo "$i,"${WIKI[$i]}",,"
  done
}
########################################

########################################
# Make CSV list of live wikis
# Filter ouput only to processes that contain 'tiddlywiki' word in command line
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
    awk '/tiddlywiki/ { print ","$4","$1","$6 }' \
    | sed 's/port=//'
}
########################################

########################################
# Merge conf and live CSV lists
# Merging based on common field "path to wiki"
# Output also live and not configured wikis
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
  local live_list="$(live2csv)"

  while IFS=, read -r -a conf_line; do # loop config
    output_line=$(printf '%s,%s,%s,%s\n' "${conf_line[@]}")
    while IFS=, read -r -a live_line; do # loop live
      if [[ "${conf_line[1]}" == "${live_line[1]}" ]]; then # merge lines
        output_line="${conf_line[0]},${conf_line[1]},${live_line[2]},${live_line[3]}"
        live_list=$(echo "$live_list" \
          | sed "/${live_line[3]}/d") # remove this line from live_list
        break # no need to continue inner loop
      fi
    done <<< "$(live2csv)"
    echo "$output_line"
  done <<< "$(conf2csv)"
  echo "$live_list" # remaning live_list
}
########################################

########################################
# Create global wiki_status_csv list
# If config path does not point to tiddlywiki.info then replace it by 'WNA'.
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
    [[ -f "${line[1]}tiddlywiki.info" ]] || line[1]="WNA"
    echo "${line[0]},${line[1]},${line[2]},${line[3]}"
  done <<< $(merge_csv)
}

########################################
# Prints formatted wiki status with header and footer
#
# Globals:
#   wiki_status_csv: used
#
# Outputs:
#   STDOUT: CSV list: key,path,pid,port + footer if WMA found
#
# Requires:
#   EXT: sed, awk, sort, grep
########################################
print_status () {
  local header="KEY,PATH,PID,PORT"
  local footer="WNA: Wiki Not Avalilable on the path configured"
  local mxpl # maximum of paths lengths

# determine max path length for formatting purpose
  mxpl=$(echo "${wiki_status_csv}" \
    | awk -F, '{ print $2 }' \
    | awk '{ print length}' \
    | sort -nr \
    | sed '1!d'
  )
  (( $mxpl < 4 )) && mxpl=6 || mxpl=$(( $mxpl + 2 ))

# final output
  echo -e "--------\n${header}\n${wiki_status_csv}" | \
    awk -F, '{ printf "%-8s %-'${mxpl}'s %-6s %-6s \n", $1, $2, $3, $4 }'
  echo "--------"
  (( $(echo "$wiki_status_csv" | grep -E -c ',WNA,') )) && echo "$footer"
}
########################################

########################################
# View all/selected running wikis in the default browser
#
# Globals:
#   wiki_status_csv: used
#
# Arguments:
#   [keylist]: space separated list of wikis key to stop, default is stop all
########################################
view_wikis () {
  declare -A ports_arr # associative array ( key port) of all running wikis
  local line
  local i
  local url="http://localhost:"

# Get ports_arr=( key port )
  while IFS="," read -a line; do # line array=( key path pid port )
    [[ -n "${line[3]}" ]] && ports_arr[${line[0]}]=${line[3]}
  done <<< "$wiki_status_csv"

  [[ ${#ports_arr[@]} -eq 0 ]] && return # there si nothing to view

# View all wikis
  if [[ $# -eq 0 ]]; then
    for i in ${ports_arr[@]}; do
      url+=$i
      xdg-open $url || x-www-browser $url || sensible-browser $url
    done
  fi

# View wikis according keys provided by CLI, prevent multiple views of one key
  while (( $# > 0 )); do # args cycle
    for i in ${!ports_arr[@]}; do
      if [[ "$1" == "$i" ]]; then
        url+=${ports_arr[$i]}
        xdg-open $url || x-www-browser $url || sensible-browser $url \
          && unset ports_arr[$i]
      fi
    done
    shift
  done
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
# Start all/selected wikis thar are not running yet
#
# Globals:
#   wiki_status_csv: used
#
# Arguments:
#   [keylist]: of wikis to run, default is all
#
# OUTPUTS:
#   STDOUT: total count of started wikis
#   STDERR: if (key path) and (key port) arrays are of unequal lengths
#   STDERR: if neither ss|netstat is not installed
#
# RETURNS:
#   exit 1: if (key path) and (key port) arrays are of unequal lengths
#   exit 2: if neither ss|netstat is not installed
#
# Requires:
#   INT: get_free_port
#   EXT: awk, ss|netstat
########################################
start_wikis () {
  local tcp_range=( {8001..8050} ) # array of ports to select from
  local tcp_busy # array of already listening ports
  local started=0 # total started count
  local line # line array
  local wport
  local key
  declare -A path_arr
  declare -A port_arr

# Get busy tcp ports with ss|nestat
  tcp_busy=( $(ss -tln 2>/dev/null \
    | awk '/LISTEN/ { print $4 }' \
    | awk -F: '$2 ~ /[0-9]+/ { print $2 }') ) \
  || tcp_busy=( $(netstat -tln 2>/dev/null \
    | awk '/LISTEN/ { print $4 }' \
    | awk -F: '$2 ~ /[0-9]+/ { print $2 }') ) \
  || echo "Tidhub requires 'ss' or 'netstat' utils installed" >&2 && exit 2

# Make path_arr (key path) and port_arr (key port) for wikis available to start
  while IFS="," read -a line; do # array=( key path pid port )
    key=${line[0]}
    path_arr[$key]="${line[1]}"
    wport=$(get_free_port tcp_range tcp_busy)
    port_arr[$key]=$wport
    tcp_busy+=($wport) # after assignment make port looks like busy
  done <<< "$(echo "$wiki_status_csv" \
    | grep -v ',WNA,\|[0-9]\+$')" # !! wikis ready to start (not WNA or running)

# Verify for each case arrays are of equal length
  [[ ${#port_arr[@]} -ne ${#path_arr[@]} ]] \
    && echo "Unexpected error" >&2 \
    && exit 1

# Start all wikis # FIXME
  if [[ $# -eq 0 ]]; then
    for key in ${!path_arr[@]}; do
      echo "Startinq wiki $key on '${path_arr[$key]}' port ${port_arr[$key]}"
      tiddlywiki "${path_arr[$key]}" \
        --listen port=${port_arr[$key]} &>/dev/null &
      (( started+=1 ))
    done
  fi

# Start wikis in bgr according keys from CLI, prevent multiple starts one key
  while (( $# > 0 )); do # args cycle
    for key in ${!path_arr[@]}; do
      if [[ "$1" == "$key" ]]; then
        echo "Startinq wiki $key on '${path_arr[$key]}' port ${port_arr[$key]}"
        tiddlywiki "${path_arr[$key]}" \
          --listen port=${port_arr[$key]} &>/dev/null &
        unset path_arr[$key]
        unset port_arr[$key]
        (( started+=1 ))
      fi
    done
    shift
  done
  echo "Started total: $started"
}
########################################

########################################
# Stop all/selected already running wikis
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
  declare -A pids_arr # associative array ( key pid ) of running & conf wikis
  local line
  local pid

  # Kill all running wikis including those not configured
  if [[ $# -eq 0 ]]; then
    while IFS="," read -a line; do # line array=(- - pid -)
      pid=${line[2]}
      if [[ $pid ]]; then
        kill $pid || kill -9 $pid && (( killed+=1 ))
      fi
    done <<< "$wiki_status_csv"
  fi

  # Kill some configured wikis according keylist
  # and prevent multiple kills of one key
  if [[ $# -gt 0 ]]; then
    # Get pids_arr=( key pid ) of running & configure wikis
    while IFS="," read -a line; do # line array=( key path pid port )
      [[ ${line[0]} ]] && [[ -n "${line[2]}" ]] && pids_arr[${line[0]}]=${line[2]}
    done <<< "$wiki_status_csv"
    # Kill them according keylist
    while (( $# > 0 )); do # args cycle
      for i in ${!pids_arr[@]}; do
        if [[ "$1" == "$i" ]]; then
          pid=${pids_arr[$i]}
          kill $pid || kill -9 $pid \
            && unset pids_arr[$i] \
            && (( killed+=1 ))
        fi
      done
      shift
    done
  fi
  echo "Stopped total: $killed"
}
########################################


########################################
### Main
########################################
main () {
# Prepare
check_rc
source "$rcfile"
wiki_status_csv=$(mk_wiki_status)

# Read opts/args and run service functions accordingly
case $1 in
  -h | --help)
    print_help
    ;;
  -s | --status)
    print_status
    ;;
  -v | --version)
    print_version
    ;;
  start)
    shift # necessary shift to provide start with keylist
    start_wikis "$@"
    wiki_status_csv=$(mk_wiki_status) # view updated status
    print_status
    ;;
  stop)
    shift # necessary shift to provide stop with keylist
    stop_wikis "$@"
    wiki_status_csv=$(mk_wiki_status) # view updated status
    print_status
    ;;
  view)
    shift # necessary shift to provide view with keylist
    view_wikis "$@"
    ;;
  *)
    [[ -z $1 ]] || echo -e "Unregognized input '$1'\n" >&2 && print_usage
    ;;
esac
}
########################################

main "$@"

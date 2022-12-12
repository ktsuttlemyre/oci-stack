#!/bin/bash

debug=false

sourced=0
if [ -n "$ZSH_VERSION" ]; then 
  case $ZSH_EVAL_CONTEXT in *:file) sourced=1;; esac
elif [ -n "$KSH_VERSION" ]; then
  [ "$(cd -- "$(dirname -- "$0")" && pwd -P)/$(basename -- "$0")" != "$(cd -- "$(dirname -- "${.sh.file}")" && pwd -P)/$(basename -- "${.sh.file}")" ] && sourced=1
elif [ -n "$BASH_VERSION" ]; then
  (return 0 2>/dev/null) && sourced=1 
else # All other shells: examine $0 for known shell binary filenames.
     # Detects `sh` and `dash`; add additional shell filenames as needed.
  case ${0##*/} in sh|-sh|dash|-dash) sourced=1;; esac
fi


declare -A ARGUMENTS=( [name]=system_root [path]=/ )
source kwargs.sh "{'name'='system_root','path'='/'}" "$@"

debug && echo "final answer is name $name path $path"


vartype() {
    local var=$( declare -p $1 )
    local reg='^declare -n [^=]+=\"([^\"]+)\"$'
    while [[ $var =~ $reg ]]; do
            var=$( declare -p ${BASH_REMATCH[1]} )
    done

    case "${var#declare -}" in
    a*)
            echo "ARRAY"
            ;;
    A*)
            echo "HASH"
            ;;
    i*)
            echo "INT"
            ;;
    x*)
            echo "EXPORT"
            ;;
    *)
            echo "OTHER"
            ;;
    esac
}



args="${@}"
ARGUMENTS=$1
#next line is a hack
unset 'ARGUMENTS[0]'
debug && echo "all script args ${@}"
debug && echo "all incoming parameter values ${args[@]}"
debug && echo "accepted agruments ${!ARGUMENTS[@]}"
debug && vartype $ARGUMENTS
debug && printf "%s\n" "${!ARGUMENTS[@]}" "${ARGUMENTS[@]}" | pr -2t

#if vartype is string then
#assume it is json and turn it into a associativearray
#declare -A myarray
#while IFS="=" read -r key value
#do
#    myarray[$key]="$value"
#done < <(jq -r 'to_entries|map("(.key)=(.value)")|.[]' file)




#VARS="`set -o posix ; set`";
#      arguments      #



#ARGUMENTS="`grep -vFe "$VARS" <<<"$(set -o posix ; set)" | grep -v ^VARS= | cut -d "=" -f 1 | tr "\n" " "`"
#ARGUMENTS=($ARGUMENTS)

# read arguments
opts=$(getopt \
  --longoptions "$(printf "%s:," "${!ARGUMENTS[@]}")" \
  --name "$(basename "$0")" \
  --options "" \
  -- "$@"
)
if [ $? -ne 0 ]; then
  exit 1
fi
#//todo try to remove eval
eval set --$opts

debug && echo "opts ==== ${opts[@]}"
env_file=""
while [[ $# -gt 0 ]]; do
  debug && echo "looking at $1 with $2 arguments ${!ARGUMENTS[@]}"
  #//todo next line is a hack
  if [ "$1" == "--" ]; then
     shift 2
     continue
  fi
  if [ "--${ARGUMENTS[${1}]+abc}" ]; then
    declare -x -g ${1:2}=$2
    export ${1:2}=$2
    env_file="$env_file\n${1:2}=$2"
  fi
  shift 2
done

if [ ! sourced ]; then
    echo "$env_file"
fi

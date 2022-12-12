#!/bin/bash
# Resources
# https://bl.ocks.org/magnetikonline/22c1eb412daa350eeceee76c97519da8
# https://stackoverflow.com/questions/4069188/how-to-pass-an-associative-array-as-argument-to-a-function-in-bash
# https://stackoverflow.com/questions/3966048/access-arguments-to-bash-script-inside-a-function
# https://stackoverflow.com/questions/35235707/bash-how-to-avoid-command-eval-set-evaluating-variables
# jq read json to associative array https://stackoverflow.com/questions/26717277/accessing-a-json-object-in-bash-associative-array-list-another-model

debug=false

# https://stackoverflow.com/questions/2683279/how-to-detect-if-a-script-is-being-sourced
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
    # https://stackoverflow.com/questions/14525296/how-do-i-check-if-variable-is-an-array
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
# https://unix.stackexchange.com/questions/366581/bash-associative-array-printing
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
  # https://stackoverflow.com/questions/13219634/easiest-way-to-check-for-an-index-or-a-key-in-an-array
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

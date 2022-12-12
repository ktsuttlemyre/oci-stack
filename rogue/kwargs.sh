#!/bin/bash

declare -A ARGUMENTS=( [name]=system_root [path]=/ )
source kwargs.sh "{'name'='system_root','path'='/'}" "$@"

echo "final answer is name $name path $path"

shipwash@penguin:~$ cat kwargs.sh 
#!/bin/bash

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
echo "all script args ${@}"
echo "all incoming parameter values ${args[@]}"
echo "accepted agruments ${!ARGUMENTS[@]}"
vartype $ARGUMENTS
printf "%s\n" "${!ARGUMENTS[@]}" "${ARGUMENTS[@]}" | pr -2t

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
echo "here"
eval set --$opts

echo "opts ==== ${opts[@]}"

while [[ $# -gt 0 ]]; do
  echo "looking at $1 with $2 arguments ${!ARGUMENTS[@]}"
  if [ "$1" == "--" ]; then
     shift 2
     continue
  fi
  if [ "--${ARGUMENTS[${1}]+abc}" ]; then
    declare -x -g ${1:2}=$2
    export ${1:2}=$2
    echo "set ${1:2} as $2"
  fi
  shift 2
done

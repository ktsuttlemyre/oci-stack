#!/usr/bin/env bash
#expect root to run this in home directory
# https://help.ubuntu.com/community/BackupYourSystem/TAR
# $1 = BACKUPNAME

declare -A ARGUMENTS=( [name]=system_root [path]=/ )

name="system_root"
path="/"

#VARS="`set -o posix ; set`";
#      arguments      #

#ARGUMENTS="`grep -vFe "$VARS" <<<"$(set -o posix ; set)" | grep -v ^VARS= | cut -d "=" -f 1 | tr "\n" " "`"
#ARGUMENTS=($ARGUMENTS)

echo "incoming parameters ${!ARGUMENTS[@]}"

# read arguments
opts=$(getopt \
  --longoptions "$(printf "%s:," "${!ARGUMENTS[@]}")" \
  --name "$(basename "$0")" \
  --options "" \
  -- "$@"
)
eval set --$opts

while [[ $# -gt 0 ]]; do
  echo "looking at $1 with $2 arguments ${!ARGUMENTS[@]}"
  if [ "--${ARGUMENTS[${1}]+abc}" ]; then
    declare -x -g ${1:2}=$2
    echo "set ${1:2} as $2"
  fi
  shift 3
done


#declare -A ARGUMENTS=( [name]=system_root [path]=/ )
#kwargs $@ args


echo "name $name path $path"


#make space
#ls -1tr | head -n -10 | xargs -d '\n' rm -f --
#make backup
#BACKUPNAME=${$1:-"backup_$(date -d "today" +"%Yy_%mm_%dd_%H:%M")"}
#tar -cvpzf "$HOME/backups/$BACKUPNAME" --exclude="$HOME/backups/" --one-file-system / 
#be sure to exclude mountpoints
#see --one-file-system argument here
#https://help.ubuntu.com/community/BackupYourSystem/TAR
#excludes=$(/proc/mounts | cut -d" " -f 2 | awk '{print " --exclude=" $0}' | tr -d "\n")
bup index --exclude="/root/backups/" --one-file-system --exclude="/root/.bup" $path
bup save --name "$name" $path

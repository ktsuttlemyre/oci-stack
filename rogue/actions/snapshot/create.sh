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


######TODO add user home directories that can login
# user_data=$(getent passwd)
# if [ -z "$var" ]; then
#   user_data=$(cat /etc/passwd)
# fi
# list_user_dirs=($(echo "$user_data" | grep  -v "/bin/false" | grep -v "/usr/sbin/nologin" | grep -v "/bin/sync" | cut -d: -f6))

#TODO create hash of users above and their home directores and make a bup branch for each so we can allow users to use backups for their home


#make space
#ls -1tr | head -n -10 | xargs -d '\n' rm -f --
#make backup
#BACKUPNAME=${$1:-"backup_$(date -d "today" +"%Yy_%mm_%dd_%H:%M")"}
#tar -cvpzf "$HOME/backups/$BACKUPNAME" --exclude="$HOME/backups/" --one-file-system / 
#be sure to exclude mountpoints
#see --one-file-system argument here
#https://help.ubuntu.com/community/BackupYourSystem/TAR
exclude_mounts=$(cat /proc/mounts | cut -d" " -f 2 | awk '{print " --exclude=" $0}' | tr -d "\n")
exclude_systems="--exclude=/dev --exclude=/proc --exclude=/sys --exclude=/tmp/ --exclude=/run/ --exclude=/mnt/ --exclude=/media/ --exclude=/lost+found"
bup index --one-file-system --exclude="/root/.bup" $exclude_mounts $exclude_systems $path
bup save --quiet --name "$name" $path

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

##################################################
######TODO exclude user home directories that can login and make them their own branch
# user_data=$(getent passwd)
# if [ -z "$var" ]; then
#   user_data=$(cat /etc/passwd)
# fi
# list_user_dirs=($(echo "$user_data" | grep  -v "/bin/false" | grep -v "/usr/sbin/nologin" | grep -v "/bin/sync" | cut -d: -f6))

#TODO create hash of users above and their home directores and make a bup branch for each so we can allow users to use backups for their home

################Use package manager to handle binaries#######
#TODO optomization to not track common binaries and use package manager to handle this
#binaries are not easily compressed so removing them will make smaller backup images
#TODO use mpm to create snapshots of installed packages
#https://github.com/kdeldycke/meta-package-manager
#mpm backup

#TODO ask package manager to list what files it is tracking and ignore those
#https://www.makeuseof.com/apt-vs-dpkg/
#apps=$(apt list --installed)
#all_apt_tracked_files=()
#candidate_files=()
#for [ app in apps ]; do
  # https://askubuntu.com/questions/408784/after-doing-a-sudo-apt-get-install-app-where-does-the-application-get-stored

  # collapse file lists into directories
  # https://superuser.com/questions/805306/how-to-find-the-common-paths-from-a-list-of-paths-files
#  files=$(dpkg -L $app)
# all_apt_tracked_files concatinate files
#done
#simplify list
#https://superuser.com/questions/805306/how-to-find-the-common-paths-from-a-list-of-paths-files
#list_of_common_apt_tracked_dirs = $(perl -lne 'BEGIN { $l="\n"; }; if ($_ !~ /^\Q$l/) { print $_; $l = $_; }')
#the above command tells us where apt tracked files are so even if a package manager installed something to a weird location outside /usr we will find it

# make a diff of files that exist vs files that are tracked

#for[list_of_common_apt_tracked_dirs in dir ]; then
# candidate_files+= $(find $dir)

#candidate_files uniq

# finally tell bup to ignore files that are 100% being tracked by package manager
# tough problem?



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

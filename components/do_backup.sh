#!/usr/bin/env bash
#expect root to run this in home directory
# https://help.ubuntu.com/community/BackupYourSystem/TAR
# $1 = BACKUPNAME

#make space
#ls -1tr | head -n -10 | xargs -d '\n' rm -f --
#make backup
#BACKUPNAME=${$1:-"backup_$(date -d "today" +"%Yy_%mm_%dd_%H:%M")"}
#tar -cvpzf "$HOME/backups/$BACKUPNAME" --exclude="$HOME/backups/" --one-file-system / 
#be sure to exclude mountpoints
#see --one-file-system argument here
#https://help.ubuntu.com/community/BackupYourSystem/TAR
#excludes=$(/proc/mounts | cut -d" " -f 2 | awk '{print " --exclude=" $0}' | tr -d "\n")
bup index --exclude="/root/backups/" --one-file-system --exclude="/root/.bup" /
bup save --name system_root /

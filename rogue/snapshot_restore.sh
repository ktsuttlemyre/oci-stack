
exclude_mounts=$(/proc/mounts | cut -d" " -f 2 | awk '{print " --exclude=" $0}' | tr -d "\n")
exclude_systems="--exclude=/dev --exclude=/proc --exclude=/sys --exclude=/tmp/ --exclude=/run/ --exclude=/mnt/ --exclude=/media/ --exclude=/lost+found"

tmp_file=$(mktemp -d -t snapshot_restoreXXXXXXXXX)
bup restore -C $tmp_file clean_system_rollback/latest/
rsync -aHAXS $tmp_file/* / --exclude $tmp_file $exclude_mounts $exclude_systems --delete
rm -rf $tmp_file

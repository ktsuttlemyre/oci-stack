unpack_to_ram=false

exclude_mounts=$(cat /proc/mounts | cut -d" " -f 2 | awk '{print " --exclude=" $0}' | tr -d "\n")
exclude_systems="--exclude=/dev --exclude=/proc --exclude=/sys --exclude=/tmp/ --exclude=/run/ --exclude=/mnt/ --exclude=/media/ --exclude=/lost+found"

tmp_file=$(mktemp -d -t snapshot-restore-XXXXXXXXX)

if [ unpack_to_ram ]; then
  mount -t tmpfs -o size=$(awk '/MemFree/ { printf "%.3f \n", $2/1024/1024 }' /proc/meminfo)G restore $tmp_file
fi

bup restore --quiet -C $tmp_file clean_system_rollback/latest/
rsync -aHAXS $tmp_file/* / --exclude $tmp_file $exclude_mounts $exclude_systems --delete

if [ unpack_to_ram ]; then
  umount $tmp_file
fi

rm -rf $tmp_file



#git repo
#curl .zip

#unzip here

cd ###


for file in $(find . -type f -name "*.perm"); do
  echo "installing $file"
  
  filename=$(basename -- "$file")
  extension="${filename##*.}"
  extension="${filename##*.}"
  filename="${filename%.*}"
  awk -v name=$filename -v ext=$extension '/-rogue-perm-/{n++}{if(n == 0){print > "" name ""}else if(n == 1){print > "" name ext ""}}' "$file"
  #load yaml into vars
  parse_yaml "$filename.perm"
  
  #TODO maybe use install?
  cp "$file" "$PATH"
  chown "$OWNER" "$PATH"
  chown "$PERMISSIONS" "$PATH"
done

install owner: root:root
path: /root/docker-compose.yml
permissions: '0644'

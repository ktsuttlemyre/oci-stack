#!/bin/bash -xe

#Slim git clone/pull read only function from public github repos 
got () {
	# 1= user 2 = repo
	BRANCH=${3:-master}
	[ -d "$2" ] && rm -rf "$2"
	curl -L -O "https://github.com/$1/$2/archive/$BRANCH.zip" | gunzip -S
}

# set a variable permenantly 
var(){
	local source
	if [[ $(type -t "$1") == function ]];
		source=$(type SECRET | tail -n +2)
	then
		declare -xg $1="$2"
		source = "export $1='$2'"
	fi
	echo "$source" | tee -a /root/.profile /home/$(whoami)/.profile
}

change_user () {
	sudo -i -u $1
	echo "Changed user [whoami: $(whoami)] [USERNAME=$USERNAME] [SUDO_USER=$SUDO_USER]"
}

SECRET() {
	oci secrets secret-bundle get-secret-bundle-by-name --vault-id $VAULT --secret-name "$1" | jq -r '.data."secret-bundle-content".content | @base64d'
}

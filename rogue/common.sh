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
	#gets a secret from vault and returns it. You should save it in a environment variable or send it directly to an app
	oci secrets secret-bundle get-secret-bundle-by-name --vault-id $VAULT --secret-name "$1" | jq -r '.data."secret-bundle-content".content | @base64d'
}

# idea from https://unix.stackexchange.com/questions/45964/scripting-htdigest-c-path-to-file-user-user-password-in-bash
htdigest_add () {
	user="$1"
	realm="$2"
	password="$3"
	outputfile="$4" #make default /etc/apache2/pw/$user
	touch "$outputfile"
	digest="$( printf "%s:%s:%s" "$user" "$realm" "$password" | 
           md5sum | awk '{print $1}' )"
	printf "%s:%s:%s\n" "$user" "$realm" "$digest" >> "$outputfile"
}
htdigest_remove () {
	user="$1"
	realm="$2"
	outputfile="$3" # make default "/etc/apache2/pw/$user"
	sed -i -e "/^$user:$realm:/d" "$outputfile"
}
htdigest_update () {
	user="$1"
	realm="$2"
	password="$3"
	outputfile="$4" # make default "/etc/apache2/pw/$user"
	digest="$( printf "%s:%s:%s" "$user" "$realm" "$password" | 
           md5sum | awk '{print $1}' )"

	sed -i -e "/^$user:$realm:/ c$user:$realm:$digest" "$outputfile"
}


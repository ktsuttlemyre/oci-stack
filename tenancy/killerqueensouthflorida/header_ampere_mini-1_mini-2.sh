#!/bin/bash -xe
#cloud_init
#https://cloudinit.readthedocs.io/en/latest/topics/examples.html
echo "Hello, this is a $(hostname) init script. If you are seeing this then the init script has started!" | tee > /init.log

#Slim git clone/pull read only function 
got () {
	# 1= user 2 = repo
	BRANCH=${3:-master}
	[ -d "$2" ] && rm -rf "$2"
	curl -L -O "https://github.com/$1/$2/archive/$BRANCH.zip" | gunzip -S
}

# set a variable permenantly 
let(){
	local source
	if [[ $(type -t "$1") == function ]];
		source=$(type SECRET | tail -n +2)
	then
		declare -xg $1="$2"
		source = "export $1='$2'"
	fi
	echo "$source" | tee -a /root/.profile /home/ubuntu/.profile
}

change_user () {
	sudo -i -u ubuntu
	echo "Changed user [whoami: $(whoami)] [USERNAME=$USERNAME] [SUDO_USER=$SUDO_USER]"
}

SECRET() {
	oci secrets secret-bundle get-secret-bundle-by-name --vault-id $VAULT --secret-name "$1" | jq -r '.data."secret-bundle-content".content | @base64d'
}

let change_user
let let
let got
let secret

#sudo user
#disable ubuntu firewall
command -v ufw > /dev/null && ufw disable

#go to admin user
change_user "ubuntu"

# install oci cli
curl -L -o /run/oci/oci_install.sh https://raw.githubusercontent.com/oracle/oci-cli/master/scripts/install/install.sh
chmod +x /run/oci/oci_install.sh
/run/oci/oci_install.sh --accept-all-defaults

#https://database-heartbeat.com/2021/10/05/auth-cli/
#depricated this was when we used policies
#set permanant
#let OCI_CLI_AUTH 'instance_principal'

#refresh shell so we can use oci cli
exec -l $SHELL

#write config to disk from envoronment variable
echo “$OCI_CONFIG” | base64 -d | tar -xz
oci setup repair-file-permissions –file ~/.oci/oci_api.pem
oci setup repair-file-permissions –file ~/.oci/config

#get secret
CLOUDFLARE_TOKEN=SECRET CLOUDFLARE_TOKEN
CLOUDFLARE_ZONEID=SECRET CLOUDFLARE_ZONEID

#install DDNS for cloudflare
#https://github.com/timothymiller/cloudflare-ddns
got "timothymiller" "cloudflare-ddns"
cat > cloudflare-ddns/config.json <<-'EOF'
	{
	  "cloudflare": [
	    {
	      "authentication": {
		"api_token": "$CLOUDFLARE_TOKEN",
	      },
	      "zone_id": "$CLOUDFLARE_ZONEID",
	      "subdomains": [
		{
		  "name": "mini.kqsfl.com",
		  "proxied": false
		}
	      ]
	    }
	  ],
	  "a": true,
	  "aaaa": true,
	  "purgeUnknownRecords": false,
	  "ttl": 300
	}
	EOF



#https://www.docker.com/blog/getting-started-with-docker-for-arm-on-linux/
curl -fsSL test.docker.com -o get-docker.sh && sh get-docker.sh
#Add ubuntu to the docker group to avoid needing sudo to run the docker command:
sudo usermod -aG docker $USERNAME 

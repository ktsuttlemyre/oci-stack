#!/bin/bash -xe
echo "Hello, this is a $(hostname) init script. If you are seeing this then the init script has started!" | tee > /init.log

#Slim git clone/pull read only function 
got () {
	# 1= user 2 = repo
	BRANCH=${3:-master}
	[ -d "$2" ] && rm -rf "$2"
	curl -L -O "https://github.com/$1/$2/archive/$BRANCH.zip" | gunzip -S
}

# set a variable permenantly 
let(){ declare -xg $1=\"$2\" ; echo \"export $1='$2'\" >> /etc/environment ; }

echo "whoami $(whoami) username: $USERNAME"
#update and install tools
apt-get update
#apt-get upgrade

#disable ubuntu firewall
ufw disable

sudo -i -u ubuntu
echo "Changed to user whoami: $(whoami) username: $USERNAME"
# install oci cli
curl -L -o /tmp/oci_install.sh https://raw.githubusercontent.com/oracle/oci-cli/master/scripts/install/install.sh
chmod +x /tmp/oci_install.sh
/tmp/oci_install.sh --accept-all-defaults

#https://database-heartbeat.com/2021/10/05/auth-cli/
#set permanant
let OCI_CLI_AUTH 'instance_principal'


SECRET() {
	oci secrets secret-bundle get-secret-bundle-by-name --vault-id $VAULT --secret-name "$1" | jq -r '.data."secret-bundle-content".content | @base64d'
}

#get secret
CLOUDFLARE_TOKEN=SECRET CLOUDFLARE_TOKEN
CLOUDFLARE_ZONEID=SECRET CLOUDFLARE_ZONEID


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

#Add the current user to the docker group to avoid needing sudo to run the docker command:
sudo usermod -aG docker $USER 

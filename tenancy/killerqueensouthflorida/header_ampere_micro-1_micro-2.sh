#!/bin/bash -xe
#cloud_init docs
#https://cloudinit.readthedocs.io/en/latest/topics/examples.html
echo "Hello, this is a $(hostname) init script. If you are seeing this then the init script has started!" | tee > /init.log

cd /root

user_admin=ubuntu
user_app=app


# run as admin user
##############################
####     USER  admin      ####
##############################
sudo -i -u $admin_user bash << 'EOF'
echo "Running as $(whoami)"
cd ~
echo "Installing OCI CLI"
curl -L -o oci_install.sh https://raw.githubusercontent.com/oracle/oci-cli/master/scripts/install/install.sh
chmod +x oci_install.sh
./oci_install.sh --accept-all-defaults

#https://database-heartbeat.com/2021/10/05/auth-cli/
#depricated this was when we used policies
#set permanant
#var OCI_CLI_AUTH 'instance_principal'

#write config to disk from envoronment variable
echo "$OCI_CONFIG" | base64 -d | tar -xz
chmod 600 "$HOME/.oci/oci_api.pem"
chmod 600 "$HOME/.oci/config"
echo "loging off $(whoami)"
EOF
echo "now root user $(whoami)"

echo "Installing bup and creating a savestate" 
apt-get install -y bup
bup init
bup index --one-file-system --exclude="/root/.bup" /
bup save --name clean_system_rollback /

echo "Customizing system"
#disable ubuntu firewall
command -v ufw > /dev/null && ufw disable

sudo -i -u $admin_user bash << 'EOF'
echo "Running as $admin_user $(whoami)"
#get secret
CLOUDFLARE_TOKEN=SECRET CLOUDFLARE_TOKEN
CLOUDFLARE_ZONEID=SECRET CLOUDFLARE_ZONEID
CLOUDFLARE_EMAIL=SECRET CLOUDFLARE_EMAIL

#install DDNS for cloudflare
#https://github.com/timothymiller/cloudflare-ddns
got "timothymiller" "cloudflare-ddns"
cat > cloudflare-ddns/config.json <<-EOF1
	{
	  "cloudflare": [
	    {
	      "authentication": {
		"api_token": "$CLOUDFLARE_TOKEN",
	      },
	      "zone_id": "$CLOUDFLARE_ZONEID",
	      "subdomains": [
		{
		  "name": "mini-1.kqsfl.com",
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
	EOF1


#lets encrypt 
CLOUDFLARE_DNS_API_TOKEN="$CLOUDFLARE_TOKEN" \
lego --email "$CLOUDFLARE_EMAIL" --dns cloudflare --domains '*.example.org' run

##########################
##    install docker    ##
##########################

#https://www.docker.com/blog/getting-started-with-docker-for-arm-on-linux/
curl -fsSL test.docker.com -o get-docker.sh && sh get-docker.sh
#Add admin_user to the docker group to avoid needing sudo to run the docker command:
sudo usermod -aG docker $admin_user 
EOF
##############################
####     USER  ROOT     ####
##############################

####################
#  Create Service  #
BOOTSCRIPT=$(cat <<-END
	docker-compose up
END
)

#change back to root and set everything else up
BOOTSCRIPT_PATH=/root/boot.sh
servicename=customboot

cat > $BOOTSCRIPT_PATH <<-EOF
	#!/usr/bin/env bash
	echo "$BOOTSCRIPT_PATH ran at \$(date)!" > /tmp/it-works
	"$BOOTSCRIPT"
EOF

chmod +x $bootscript

cat > /etc/systemd/system/$servicename.service <<-EOF
	[Service]
	ExecStart=$bootscript
	[Install]
	WantedBy=default.target
	EOF

systemctl enable $servicename


# https://askubuntu.com/questions/58575/add-lines-to-cron-from-script
line="* * * * * /path/to/command"
(crontab -u $(whoami) -l; echo "$line" ) | crontab -u $(whoami) -




echo "Hello, this is a $(hostname) init script. If you are seeing this then the init script has finished! Restarting now" | tee >> /init_start
sudo shutodwn -r now

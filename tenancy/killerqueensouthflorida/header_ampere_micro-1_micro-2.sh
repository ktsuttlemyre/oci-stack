#!/bin/bash -xe
#cloud_init docs
#https://cloudinit.readthedocs.io/en/latest/topics/examples.html
echo "Hello, this is a $(hostname) init script. If you are seeing this then the init script has started!" | tee > /init.log

cd /root
apt-get install -y bup
bup index --one-file-system --exclude="/root/.bup" /
bup save --name clean_system /


user_admin="ubuntu"
user_app="app"


#sudo user
#disable ubuntu firewall
command -v ufw > /dev/null && ufw disable


# run as admin user
##############################
####     USER  admin      ####
##############################
sudo -i -u "$admin_user" bash << EOF

# install oci cli
curl -L -o /run/oci/oci_install.sh https://raw.githubusercontent.com/oracle/oci-cli/master/scripts/install/install.sh
chmod +x /run/oci/oci_install.sh
/run/oci/oci_install.sh --accept-all-defaults

#https://database-heartbeat.com/2021/10/05/auth-cli/
#depricated this was when we used policies
#set permanant
#let OCI_CLI_AUTH 'instance_principal'
EOF

#purposely end and restart the admin user session here
#refresh shell so we can use oci cli
##############################
####     USER  admin      ####
##############################
sudo -i -u "$user_admin" bash << EOF
#write config to disk from envoronment variable
echo "$OCI_CONFIG" | base64 -d | tar -xz
oci setup repair-file-permissions –file ~/.oci/oci_api.pem
oci setup repair-file-permissions –file ~/.oci/config

#get secret
CLOUDFLARE_TOKEN=SECRET CLOUDFLARE_TOKEN
CLOUDFLARE_ZONEID=SECRET CLOUDFLARE_ZONEID

#install DDNS for cloudflare
#https://github.com/timothymiller/cloudflare-ddns
got "timothymiller" "cloudflare-ddns"
cat > cloudflare-ddns/config.json <<-'EOF1'
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
	# https://docs.datarhei.com/restreamer/getting-started/quick-start
	docker run -d --restart=always --name restreamer \
		-v /opt/restreamer/config:/core/config \
		-v /opt/restreamer/data:/core/data \
		-p 8080:8080 -p 8181:8181 \
		-p 1935:1935 -p 1936:1936 \
		-p 6000:6000/udp \
		--user "$user_app"\
		datarhei/restreamer:latest
END
)

#change back to root and set everything else up
BOOTSCRIPT_PATH=/root/boot.sh
servicename=customboot

cat > $BOOTSCRIPT_PATH <<-'EOF'
	#!/usr/bin/env bash
	echo "$BOOTSCRIPT_PATH ran at \$(date)!" > /tmp/it-works
	"$BOOTSCRIPT"
EOF

chmod +x $bootscript

cat > /etc/systemd/system/$servicename.service <<-'EOF'
	[Service]
	ExecStart=$bootscript
	[Install]
	WantedBy=default.target
	EOF

systemctl enable $servicename


apt-get install nginx

#https://stackoverflow.com/questions/21064401/route-different-proxy-based-on-subdomain-request-in-nginx
server {
  server_name sub1.example.com;
  location / {
    proxy_pass http://127.0.0.1:xxxx;
  }
}
server {
  server_name sub2.example.com;
  location / {
    proxy_pass http://127.0.0.1:xxxx;
  }
}
#server {
#    server_name   ~^(www\.)?(?<domain>.+)$;

#    location / {
#        root   /sites/$domain;
#    }
#}


# https://askubuntu.com/questions/58575/add-lines-to-cron-from-script
line="* * * * * /path/to/command"
(crontab -u $(whoami) -l; echo "$line" ) | crontab -u $(whoami) -




echo "Hello, this is a $(hostname) init script. If you are seeing this then the init script has finished! Restarting now" | tee >> /init_start
sudo shutodwn -r now

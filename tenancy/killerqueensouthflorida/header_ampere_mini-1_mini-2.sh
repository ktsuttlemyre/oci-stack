#!/bin/bash -xe
#cloud_init docs
#https://cloudinit.readthedocs.io/en/latest/topics/examples.html
echo "Hello, this is a $(hostname) init script. If you are seeing this then the init script has started!" | tee > /init.log

#sudo user
#disable ubuntu firewall
command -v ufw > /dev/null && ufw disable


#go to admin user ubuntu
##############################
####     USER  UBUNTU     ####
##############################
sudo -i -u ubuntu bash << EOF

# install oci cli
curl -L -o /run/oci/oci_install.sh https://raw.githubusercontent.com/oracle/oci-cli/master/scripts/install/install.sh
chmod +x /run/oci/oci_install.sh
/run/oci/oci_install.sh --accept-all-defaults

#https://database-heartbeat.com/2021/10/05/auth-cli/
#depricated this was when we used policies
#set permanant
#let OCI_CLI_AUTH 'instance_principal'
EOF

#purposely end and restart the session here
#refresh shell so we can use oci cli
##############################
####     USER  UBUNTU     ####
##############################
sudo -i -u ubuntu bash << EOF
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
	EOF1



#https://www.docker.com/blog/getting-started-with-docker-for-arm-on-linux/
curl -fsSL test.docker.com -o get-docker.sh && sh get-docker.sh
#Add ubuntu to the docker group to avoid needing sudo to run the docker command:
sudo usermod -aG docker $USERNAME 

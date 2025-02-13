#!/bin/bash -xe
echo "Hello, this is a micro init script. If you are seeing this then the init script has worked!" > ./init_success


sudo apt-get update
#sudo apt-get upgrade

#disable ubuntu firewall
ufw disable


#https://www.docker.com/blog/getting-started-with-docker-for-arm-on-linux/
curl -fsSL test.docker.com -o get-docker.sh && sh get-docker.sh

#Add the current user to the docker group to avoid needing sudo to run the docker command:
sudo usermod -aG docker $USER 


####################
#  Create Service  #
bootscript=/root/boot.sh
servicename=customboot

cat > $bootscript <<-'EOF'
	#!/usr/bin/env bash
	echo "$bootscript ran at \$(date)!" > /tmp/it-works
	# https://docs.datarhei.com/restreamer/getting-started/quick-start
	docker run -d --restart=always --name restreamer \
		-v /opt/restreamer/config:/core/config \
		-v /opt/restreamer/data:/core/data \
		-p 8080:8080 -p 8181:8181 \
		-p 1935:1935 -p 1936:1936 \
		-p 6000:6000/udp \
		datarhei/restreamer:latest
EOF

chmod +x $bootscript

cat > /etc/systemd/system/$servicename.service <<-'EOF'
	[Service]
	ExecStart=$bootscript
	[Install]
	WantedBy=default.target
	EOF

systemctl enable $servicename

sudo shutdown -r now

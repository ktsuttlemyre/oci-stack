sudo -i
echo "Changed to user whoami: $(whoami) username: $USERNAME"

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


echo "Hello, this is a $(hostname) init script. If you are seeing this then the init script has finished!" | tee >> /init_start
sudo shutodwn -r now

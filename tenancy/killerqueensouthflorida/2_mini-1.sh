
#change back to root and set everything else up
sudo -i
echo "Changed to user whoami: $(whoami) username: $USERNAME"
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

echo "Hello, this is a $(hostname) init script. If you are seeing this then the init script has finished!" | tee >> /init_start
sudo shutodwn -r now

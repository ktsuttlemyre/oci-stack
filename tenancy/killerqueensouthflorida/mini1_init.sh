#!/bin/bash -xe
echo "Hello, this is a ampere init script. If you are seeing this then the init script has worked!" > ./init_success

echo "whoami $(whoami) username= $USERNAME"
#update and install tools
apt update

sudo -i -u ubuntu
echo "whoami $(whoami) username= $USERNAME"
sudo -i
echo "whoami $(whoami) username= $USERNAME"


echo "done restarting"

sudo shutodwn -r now

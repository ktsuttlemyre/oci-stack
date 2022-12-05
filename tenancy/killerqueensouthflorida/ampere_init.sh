#!/bin/bash -xe
echo "Hello, this is a ampere init script. If you are seeing this then the init script has worked!" > ./init_success

echo "whoami $(whoami) username= $USERNAME"

sudo apt-get update
sudo apt-get install -y nano jq


# wget https://raw.githubusercontent.com/dokku/dokku/v0.28.4/bootstrap.sh
# sudo DOKKU_TAG=v0.28.4 bash bootstrap.sh
# #set ssh key for current user
# sudo cat ~/.ssh/authorized_keys | sudo dokku ssh-keys:add admin
# dokku domains:set-global dokku.kqsfl.com

# #install dokku interface
# wget https://raw.githubusercontent.com/ledokku/ledokku/v0.7.0/ledokku-bootstrap.sh
# sudo bash ledokku-bootstrap.sh

# #https://docs.oracle.com/en-us/iaas/developer-tutorials/tutorials/apache-on-ubuntu/01oci-ubuntu-apache-summary.htm
# sudo iptables -I INPUT 6 -m state --state NEW -p tcp --dport 80 -j ACCEPT
# sudo iptables -I INPUT 6 -m state --state NEW -p tcp --dport 443 -j ACCEPT

# sudo netfilter-persistent save


# eval `ssh-agent -s`




# # manual step
# #run this from the cloud shell
# echo "tenancy OCID:"
# oci iam compartment list \
# --all \
# --compartment-id-in-subtree true \
# --access-level ACCESSIBLE \
# --include-root \
# --raw-output \
# --query "data[?contains(\"id\",'tenancy')].id | [0]"

# ./connect.sh
# bash -c "$(curl -L https://raw.githubusercontent.com/oracle/oci-cli/master/scripts/install/install.sh)" –accept-all-defaults

# echo "user OCID: ocid1.user.oc1..aaaaaaaash3evstllsaib2txvgtmlnpiumlgaci7uuc6byaxkshnzhwvbraa"
# echo "tenancy OCID: ocid1.tenancy.oc1..aaaaaaaa5epv2c4htabogvcriwrzdgi5toijz7fqyfvwyknlkggfa2cygquq"
# echo "region: 38"
# oci setup config


# cat /home/$USER/.oci/oci_api_key_public.pem

sudo shutdown -r now

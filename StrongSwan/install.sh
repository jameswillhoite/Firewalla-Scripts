#!/bin/bash

#Put the full path of this folder
DIR="/home/pi/IKEv2"

#Fill in the path to your config file that should be installed. This is like the
# IKE_Example_Config.conf file that is in the config directory
IKECONFIGFILE="IKE_Example_Config.conf""


TAG=ikev2_install


logger -t $TAG "Running install script"

#Check to see if this script has already run
if [ -f "/etc/ipsec.d/ikev2_installed" ]; then
  logger -t $TAG "Service is already installed"
  exit 0
fi

#Check to see if there is a lock on the apt-get
count=0
APT_LK=/var/lib/apt/lists/lock
PKG_LK=/var/lib/dpkg/lock
while fuser "$APT_LK" "$PKG_LK" >/dev/null 2>&1 \
  || lsof "$APT_LK" >/dev/null 2>&1 || lsof "$PKG_LK" >/dev/null 2>&1; do
  [ "$count" = "0" ] && logger -t $TAG "Waiting for apt to be available..."
  [ "$count" -ge "60" ] && logger -t $TAG "Could not get apt/dpkg lock" && exit 1
  count=$((count+1))
  sleep 3
done

#Install StrongSwan
sudo apt-get install -yq --no-install-recommends strongswan strongswan-pki charon-cmd libcharon-standard-plugins libcharon-extra-plugins

logger -t $TAG "Installed required dependencies"

sleep 1

#Stop the Service
logger -t $TAG "Stopping StrongSwan"
sudo systemctl stop strongswan

sleep 1

logger -t $TAG "Adjusting Apparmor profiles"

#Check to see if there is a Apparmor profile for charon, if so, then disable it
if [ -f /etc/apparmor.d/usr.lib.ipsec.charon ]; then
  sudo ln -s /etc/apparmor.d/usr.lib.ipsec.charon /etc/apparmor.d/disable/
  sudo apparmor_parser -R /etc/apparmor.d/usr.lib.ipsec.charon
fi
if [ -f /etc/apparmor.d/usr.lib.ipsec.lookip ]; then
  sudo ln -s /etc/apparmor.d/usr.lib.ipsec.lookip /etc/apparmor.d/disable/
  sudo apparmor_parser -R /etc/apparmor.d/usr.lib.ipsec.lookip
fi
if [ -f /etc/apparmor.d/usr.lib.ipsec.stroke ]; then
  echo "Disable the ipsec.stroke in apparmor"
  sudo ln -s /etc/apparmor.d/usr.lib.ipsec.stroke /etc/apparmor.d/disable/
  echo "Reload the Apparmor Profile"
  sudo apparmor_parser -R /etc/apparmor.d/usr.lib.ipsec.stroke
fi

logger -t $TAG "Backing up ipsec.conf and ipsec.secrets"

#make a copy of ipsec.conf
sudo mv /etc/ipsec.conf /etc/ipsec.conf.bak
sudo mv /etc/ipsec.secrets /etc/ipsec.secrets.bak


logger -t $TAG "Copy over server certificate"

#Copy the Server Certificates to the ipsec.d folder
if ! [ -f "/etc/ipsec.d/cacerts" ]; then
  echo "coping over server certificates"
  sudo cp -r $DIR/certs/pki/* /etc/ipsec.d/
fi

logger -t $TAG "Link the ipsec.secrets file"

#Link the new ipsec.secrets file that has the password for the client and remote
sudo ln -s $DIR/config/ipsec.secrets /etc/ipsec.secrets

logger -t $TAG "Checking to see if the includes is in the ipsec.conf file"

#check to see if the includes is in the ipsec.conf file
sudo ln -s $DIR/config/ipsec.conf /etc/ipsec.conf


#add the required rules to allow incoming LKEv2 connections
logger -t $TAG "Adding the required rules for incoming IKEv2 connections"

sudo iptables -I FW_INPUT_ACCEPT -p udp --dport 500 -j ACCEPT -m comment --comment "Added via James Willhoite IKEv2 Install Script"
sudo iptables -I FW_INPUT_ACCEPT -p tcp --dport 500 -j ACCEPT -m comment --comment "Added via James Willhoite IKEv2 Install Script"
sudo iptables -I FW_INPUT_ACCEPT -p udp --dport 1701 -j ACCEPT -m comment --comment "Added via James Willhoite IKEv2 Install Script"
sudo iptables -I FW_INPUT_ACCEPT -p tcp --dport 1701 -j ACCEPT -m comment --comment "Added via James Willhoite IKEv2 Install Script"
sudo iptables -I FW_INPUT_ACCEPT -p udp --dport 4500 -j ACCEPT -m comment --comment "Added via James Willhoite IKEv2 Install Script"
sudo iptables -I FW_INPUT_ACCEPT -p tcp --dport 4500 -j ACCEPT -m comment --comment "Added via James Willhoite IKEv2 Install Script"

if ! [ -z "${IKECONFIGFILE}" ]
then
  logger -t $TAG "Linking the ${IKECONFIGFILE} file"
  echo "Linking your main config file ${IKECONFIGFILE}" 
  sudo ln -s $DIR/config/${IKECONFIGFILE} /etc/ipsec.d/${IKECONFIGFILE}
fi


#Install the Full Tunnel IKEv2 VPN
#source "${DIR}/config/ike-full/ike-full-install.sh"

#Install the split tunnel
#source "${DIR}/config/ike-split/ike-split-install.sh"


logger -t $TAG "Starting StrongSwan"
#Start Strong Swan
sudo systemctl start strongswan

#Add the file that tells script it was already run
sudo echo "1" | sudo tee /etc/ipsec.d/ikev2_installed

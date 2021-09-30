#!/usr/bin/env bash

HOME="/home/pi/IKEv2"
CERT="${HOME}/certs"
PRIV="${HOME}/private"
CONF="${HOME}/config/ike-full"

#Fill in the file name for the server key
SERVERKEY="vpn.jameswillhoite.com-server-key.pem"

#Fill in the file name for the server certificate
SERVERCERT="vpn.jameswillhoite.com-server-cert.pem"

#copy the server keys
if ! [ -f "/etc/ipsec.d/private/${SERVERKEY}" ]; then
  sudo cp "${PRIV}/${SERVERKEY}" "/etc/ipsec.d/private/"
fi

if ! [ -f "/etc/ipsec.d/certs/${SERVERCERT}" ]; then
  sudo cp "${CERT}/${SERVERCERT}" "/etc/ipsec.d/certs/"
fi

#Add the iptables rules for the IKEv2-Full-Tunnel to redirect that subnet
sudo iptables -t nat -I POSTROUTING 1 -s 10.10.20.0/24 -o eth0 -m policy \
  --pol ipsec --dir out -j ACCEPT -m comment --comment "Added via James Willhoite IKEv2 Install Script"

sudo iptables -t nat -I POSTROUTING 2 -s 10.10.20.0/24 -o eth0 -j MASQUERADE \
  -m comment --comment "Added via James Willhoite IKEv2 Install Script"

sudo iptables -t mangle -I FORWARD --match policy \
  --pol ipsec --dir in -s 10.10.20.0/24 -o eth0 \
  -p tcp -m tcp --tcp-flags SYN,RST SYN -m tcpmss --mss 1361:1536 \
  -j TCPMSS --set-mss 1360 \
  -m comment --comment "Added via James Willhoite IKEv2 Install Script"

#Link the Conf File
sudo ln -s "${CONF}/ike-full.conf" "/etc/ipsec.d/ike-full.conf";
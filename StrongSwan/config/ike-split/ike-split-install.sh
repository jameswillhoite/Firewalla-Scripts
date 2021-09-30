#!/usr/bin/env bash

HOME="/home/pi/IKEv2"
CERT="${HOME}/certs"
PRIV="${HOME}/private"
CONF="${HOME}/config/ike-split"

#Fill in the Server Key
SERVERKEY="vpn.jameswillhoite.com-server-key.pem"

#Fill in the Server Cert
SERVERCERT="vpn.jameswillhoite.com-server-cert.pem"

#copy the server keys
if ! [ -f "/etc/ipsec.d/private/${SERVERKEY}" ]; then
  sudo cp "${PRIV}/${SERVERKEY}" "/etc/ipsec.d/private/"
fi

if ! [ -f "/etc/ipsec.d/certs/${SERVERCERT}" ]; then
  sudo cp "${CERT}/${SERVERCERT} "/etc/ipsec.d/certs/"
fi

#Link the Conf File
sudo ln -s "${CONF}/ike-split.conf" "/etc/ipsec.d/ike-split.conf";
#!/bin/bash

# First argument: Client identifier

EASY_RSA=/home/pi/openvpn/easy-rsa
KEY_DIR=${EASY_RSA}/keys
OUTPUT_DIR=/home/pi/openvpn/client_conf
BASE_CONFIG=${OUTPUT_DIR}/base.conf
VPN_USER_NAME=$1
GEN_KEY=1

if [ -z $VPN_USER_NAME ]; then
        echo -e "Usage: $0 <user_name>\n"
        exit
fi

#Check to see if the username is already taken

if [ -f ${EASY_RSA}/keys/${VPN_USER_NAME}.crt ]; then
        read -p "This username exists, change the password?! [n]" yn
        case $yn in
                [Yy]* ) openssl rsa -in ${KEY_DIR}/${VPN_USER_NAME}.key -out ${KEY_DIR}/${VPN_USER_NAME}.key -des3; GEN_KEY=0; ;;
                [Nn]* ) ;;
                * ) exit;;
        esac
else
        echo -e "Creating the Key for ${VPN_USER_NAME}\n"
fi


if [ $GEN_KEY -eq 1 ]; then
        source ${EASY_RSA}/vars
        ${EASY_RSA}/build-key-pass ${VPN_USER_NAME}
fi


echo -e "Creating the OpenVPN config file\n"

cat ${BASE_CONFIG} \
    <(echo -e '<ca>') \
    ${KEY_DIR}/ca.crt \
    <(echo -e '</ca>\n<cert>') \
    ${KEY_DIR}/${VPN_USER_NAME}.crt \
    <(echo -e '</cert>\n<key>') \
    ${KEY_DIR}/${VPN_USER_NAME}.key \
    <(echo -e '</key>\n<tls-auth>') \
    ${KEY_DIR}/ta.key \
    <(echo -e '</tls-auth>') \
    > ${OUTPUT_DIR}/${VPN_USER_NAME}.ovpn

echo -e "Configuration file completed. The file is located at\n\n${OUTPUT_DIR}/${VPN_USER_NAME}.ovpn\n"

exit

#!/usr/bin/env bash

##Main Directory of the IKE Folder
HOME="/home/pi/IKEv2"


#DON'T CHANGE ANYTHING BELOW THIS LINE


#All the PKI certificates
PKI="${HOME}/certs/pki"

# This is what you will use for IKEv2
CADIR="${PKI}/cacerts"

#These are the private keys
PRIVDIR="${PKI}/private"

#This is for the Servers
CERTSDIR="${PKI}/certs"

#Check to see if the ROOT Certificate (CA) is in place
if ! [ -f "${PRIVDIR}/ca-key.pem" ]
then
  echo "No Root Certificate found. Creating...."
  ipsec pki --gen --type rsa --size 4096 --outform pem > "${PRIVDIR}/ca-key.pem"

  if ! [ -f "${PRIVDIR}/ca-key.pem" ]
  then
    echo "Could not create the ca-key.pem"
    exit 1
  fi

  #This CN doesn't matter
  ipsec pki --self --ca --lifetime 3650 --in "${PRIVDIR}/ca-key.pem" \
    --type rsa --dn "CN=VPN root CA" --outform pem > "${CADIR}/ca-cert.pem"

  if ! [ -f "${CADIR}/ca-cert.pem" ]
  then
    echo "Could not create the ca-cert.pem"
    exit 1
  fi

fi

echo "What is the server name or IP address to use for the Certificate? "
read -r -p "Name or IP: " CN

if [ -z "${CN}" ]
then
  echo "Invalid Name or IP Address"
  exit 1
fi

SERVERKEY="${CN}-server-key.pem"
SERVERCERT="${CN}-server-cert.pem"

#Check to see if there is one already with this name
if [ -f "${PRIVDIR}/${SERVERKEY}" ]
then
  echo "This Server key already exists. Do you want to continue?"
  read -p "[Y]es / [N]o: " YN

  if [[ -z "${YN}" || "${YN}" == "N" || "${YN}" == "n" ]]
  then
    exit 1
  fi

fi

#Generate the Private Key
ipsec pki --gen --type rsa --size 4096 --outform pem > "${PRIVDIR}/${SERVERKEY}"

if ! [ -f "${PRIVDIR}/${SERVERKEY}" ]
then
  echo "Could not create the server private key"
  exit 1
fi

#Generate the Server Certificate
ipsec pki --pub --in "${PRIVDIR}/${SERVERKEY}" --type rsa \
    | ipsec pki --issue --lifetime 1825 \
        --cacert "${CADIR}/ca-cert.pem" \
        --cakey "${PRIVDIR}/ca-key.pem" \
        --dn "CN=${CN}" --san "${CN}" \
        --flag serverAuth --flag ikeIntermediate --outform pem \
    >  "${CERTSDIR}/${SERVERCERT}"

if ! [ -f "${CERTSDIR}/${SERVERCERT}" ]
then
  echo "Could not create the server certificate"
  exit 1
fi

#Copy the server key to the ipsec folder
cp "${CERTSDIR}/${SERVERCERT}" "/etc/ipsec.d/certs/${SERVERCERT}"
cp "${PRIVDIR}/${SERVERKEY}" "/etc/ipsec.d/private/${SERVERKEY}"

echo "The Server Key is located at: "
echo "${PRIVDIR}/${SERVERKEY}"
echo ""
echo "The Server Certificate is located at: "
echo "${CERTSDIR}/${SERVERCERT}"
echo ""



# Multi-User OpenVPN
A small script to help adding and changeng the password of the new User for the Firewalla Gold

# Setup
1) Open the "base.conf" file and adjust the "remote" ip/url to point to your Firewalla Static Url
2) Place the "base.conf" file in /home/pi/openvpn/client_conf or update the make_config.sh file to point to where you saved the "base.conf" file
3) Change the "make_config.sh" file to be executable
4) Type in "sudo ./make_config.sh \<username\>" where \<username\> is the name of the user you want to create.

**Note** If the user already exists, this will change the password for that user.

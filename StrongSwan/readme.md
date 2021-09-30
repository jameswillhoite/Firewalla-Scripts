## StrongSwan VPN 

These are the files I use to setup the StronSwan VPN on my Firewalla Gold. I've adjusted some files to be more "Generic" to allow others to use.

Install as follows

1) Create a Folder in the `/home/pi` directory to place these file in. (Ex. /home/pi/IKEv2)
2) Copy the files into that folder
3) Edit the "install.sh" file and fill in the folder path you just created for variable `DIR` on line 4
4) Edit the `IKECONFIGFILE` variable with the name of the config file you will be creating (This is for the connection to another vpn provider, Leave empty if you don't want to make a connection there.)
5) Save and close this file
6) To make a connection to a IKEv2 server then continue with 7. If you want to just host your own, then continue to step 8 
7) Go into directory `config` and make a copy of the `IKE_Example_Config.conf` file. This will be the config file that will be used to make a connection to another vpn provider
8) Inside the `config` directory is a script called `create_certificate.sh`. This only needs to be run once to create the certificates. This will create the main server certificate, and then create any other certificate you need. It will ask for a Common Name (CN). This will be used as the `leftid` in the config scripts.
9) You have two options, Split Tunnel, or Full tunnel. In the `config` directory there are 2 other directories. `ike-full` and `ike-split`. There are two different config files in there for example purposes. Either copy or edit them. You must go into the `install.sh` script 
 and un-comment the line(s) you want to use. Look toward the bottom of the install script for the lines. Don't forget to place the Common Name (CN) in the `leftid` in whatever config file you want to use.
10) Edit the `config/ipsec.secrets` file and place a username and password in that file to use. There are examples in that file but the format is `username : EAP password`
11) The last file to edit is in the main directory called `_updown.sh`, edit this file and place your subnet you want to access in the variable called `SUBNETTOROUTE` then save and close that file
12) You are ready to run the install script. Make sure the `install.sh` script has execute permissions (755) and issue `sudo ./install.sh` to install StrongSwan.
13) If you want the script to run whenever the Firewalla reboots then issue the following command `sudo ln -s /full/path/to/install.sh /home/pi/.firewalla/config/post_main.d/strong_swan_install.sh` just make sure you subsitute the /full/path/to/install.sh with the actual path to the install script


If anything is not right, then restart the Firewalla and everything will be reset. **Don't link the install script in step 13 until you know it works!**

If you would like some more information [HERE](https://www.digitalocean.com/community/tutorials/how-to-set-up-an-ikev2-vpn-server-with-strongswan-on-ubuntu-18-04-2) is the site I used to create these scripts with some modifcations.

Also you can visit [StrongSwan.org](https://wiki.strongswan.org/projects/strongswan) to look at more examples of config files and more information about L2TP and IKEv2.

***Please be aware, if you are connecting to a VPN provider then your entire network will be linked to that provider. There is no User Interface like FireWalla's OpenVPN and Wireguard to use***
**You must add blocking rules to disallow other networks to access the subnets**

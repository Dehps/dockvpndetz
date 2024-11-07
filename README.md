# opnvpndetz

Welcome to the opnvpndetz repository, this repository host a Dockerfile and some bash script to quickly setup an OpenVPN certs based authentication.
This can be helpful if you wanna access to your Homelab from work or remote place.


## Dockerfile

The docker image is built from debian:latest, openvpn ipcalc iptables openssl net-tools zip packages are installed from official repository
EasyRSA is installed from github because the current version for Debian is 3.1.0 the feature build-server-certificate-full isn't working in this version.

Since you get your HomeOPVPN work i recommend you to tagged your docker image somewhere and use a Docker-compose file to run it.

### Files Folders


files
├ ─ ─  bin
├ ─ ─  configuration
└ ─ ─  easyrsa

### bin subfolders
The "bin" folder contains binaries:easyrsa and the dockerfile entrypoint.



### configuration subfolder

The configuration folder contains some bashscript that are runned by the docker entrypoint and some var files (client.sh and default_vars.sh)


  #### clients.sh

  This file contains clients list and the passphrase of there private key.

  #### create_server_config.sh

  This script generate the OpenVPN server.conf

  #### create_clients_config.sh

  This script generate the OpenVPN clients-files from the clients.sh list.

  #### default_vars.sh

  This file contains all environment vars from the feature.

  #### set_defaults.sh

  This script is the first script launched by entrypoint, it controlls vars setup value and set some value to Vars Unset.

  #### setup_networking.sh

  This script setup network for the feature, please not that you should add the --cap-add=NET_ADMIN to VPN be working through docker host.
  
  #### setup_pki.sh

  This script init the pki and build ta.key (diffie-hellman key), build ca cert, server cert and clients certs, then export client certs in /etc/pki/client-export.


### easyrsa subfolders

The easyrsa folder contains easyrsa Vars and the easyrsa conf.


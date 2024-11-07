# Welcome to the opnvpndetz Repository

This repository hosts a Dockerfile and several Bash scripts to quickly set up an OpenVPN authentication system based on certificates. This can be helpful if you want to access your homelab from work or a remote location.

## Dockerfile

The Docker image is built from `debian:latest`, and the packages `openvpn`, `ipcalc`, `iptables`, `openssl`, `net-tools`, and `zip` are installed from the official repository. EasyRSA is installed from GitHub because the current version available for Debian (3.1.0) does not support the `build-server-certificate-full` feature.

Once you have your Home OpenVPN setup working, I recommend tagging your Docker image and using a Docker Compose file to run it.

## Getting Started with Docker

I recommend using the Docker Compose plugin, as it is well-suited for running a VPN service. You need to set the `$OVPN_SERVER_CN` environment variable to run the container, and you must include `--cap-add=NET_ADMIN`.

### Basic Run Command

```bash
docker run --name Myopenvpn -p 1194:1194/tcp -v /PATH/TO/HOST/VOLUMES:/etc/openvpn -e "OVPN_SERVER_CN=MY.VPN.DOMAIN" --cap-add=NET_ADMIN myimage:mytag
```
### Run with your personal users
```bash  
  docker run --name Myopenvpn -p 1194:1194/tcp -v /PATH/TO/HOST/VOLUMES:/etc/openvpn -e "OVPN_SERVER_CN=MY.VPN.DOMAIN" -e "USERS=toto,bob" --cap-add=NET_ADMINmyimage:mytag
```
here this command will create toto and bob clients user.
  
## Docker-Compose

As it be a VPN service i recommend you to use docker-compose to up your container.
See docker-compose file syntax in repo to help you.

## Export clients conf

In the PKI_DIR/client-export/ dir a ZIP file with client.ovpn and all files needed (cert,key,ca,ta.key and passphrase) note that the passphrase is random generatly if you wanna set your passphrase you can set your clients and passphrase in clients.sh

## File and Folder Structure


'''
files
│
├───bin
│
├───configuration
│
└───easyrsa
'''
### Bin Subfolder

The `bin` folder contains binaries, including `easyrsa` and the Dockerfile entrypoint.

### Configuration Subfolder

The `configuration` folder contains several Bash scripts that are executed by the Docker entrypoint, along with variable files (`client.sh` and `default_vars.sh`).

- **clients.sh**: This file contains the list of clients and the passphrases for their private keys.
- **create_server_config.sh**: This script generates the `OpenVPN server.conf` file.
- **create_clients_config.sh**: This script generates the OpenVPN client configuration files from the list in `clients.sh`.
- **default_vars.sh**: This file contains all environment variables for the feature.
- **setup_networking.sh**: This script configures the networking for the feature. Note that you should add `--cap-add=NET_ADMIN` for the VPN to function properly in the Docker host.
- **setup_pki.sh**: This script initializes the PKI, builds the `ta.key` (Diffie-Hellman key), generates the CA certificate, server certificate, and client certificates, then exports the client certificates to `/etc/pki/client-export`.

### EasyRSA Subfolder

The `easyrsa` folder contains the EasyRSA variables and configuration files.

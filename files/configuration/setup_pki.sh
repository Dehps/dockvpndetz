# SET CONIG DIRECTORY
CONFIGFILES="/opt/configuration"

#IMPORT VPN CLIENTS VAR
source $CONFIGFILES/client.sh


# IF SERVER CERTIFICATE WITH OVPN_SERVER COMMON NAME IS FIND OR $REGENERATE_CERTS IS SET TO TRUE WE ENTER THIS CONDITION
if [ ! -f "$PKI_DIR/issued/$OVPN_SERVER_CN.crt" ] || [ "$REGENERATE_CERTS" == 'true' ]; then

# init pki
 echo "easyrsa: creating server certs"
 sed -i 's/^RANDFILE/#RANDFILE/g' /opt/easyrsa/openssl-easyrsa.cnf
 EASYCMD="/opt/easyrsa/easyrsa"
 . /opt/easyrsa/pki_vars
 $EASYCMD init-pki
 

# GENERATE CA
 $EASYCMD build-ca nopass


# GENERATE DIFFIE-HELMAN
 $EASYCMD gen-dh
 openvpn --genkey secret $PKI_DIR/ta.key
 
 # GENERATE SERVER CERTIFICATE WITH OVPN_SERVER COMMON NAME
 $EASYCMD build-server-full "$OVPN_SERVER_CN" nopass

fi

# IF GENERATE_CLIENT_CERTIFICATE SET TO TRUE THEN WE GENERATE CLIENT CERTIFICATE FROM CLIENTS VARS
if [ "$GENERATE_CLIENT_CERTIFICATE" == "true" ]; then
    echo "easyrsa: creating client certs"
    
    # FOR ANY ENTRY IN TAB $CLIENTS
    for CLIENT in "${CLIENTS[@]}"; do
        CERT_PATH="/etc/openvpn/pki/issued/${CLIENT}.crt"
        
        # IF CLIENT CERT ALREADY EXIST WE DO NOTHING
        if [ -f "$CERT_PATH" ]; then
            echo "Certificate for client '$CLIENT' already exists. Skipping generation."
        

        # ELSE WE GENERATE CLIENT CERT
        else

        # DEFINE WHERE IS EASYRSA
                EASYCMD="/opt/easyrsa/easyrsa"
                . /opt/easyrsa/pki_vars
                echo "Generating certificate for client: $CLIENT"
                
        # DEFINE THE PASSPHRASE OF CLIENT KEY FROM CLIENTS VARS
                EASYRSA_PASSOUT="${PASSPHRASES[$CLIENT]}"
                $EASYCMD --passout=pass:$EASYRSA_PASSOUT build-client-full "$CLIENT"
                

        # GENERATE AN ARCHIVE WITH ca.crt, ta/key, CLIENT.crt,CLIENT.key to export configuration to your client HOST       
                mkdir -p $PKI_DIR/client-export/${CLIENT}
                passphrase_file=$PKI_DIR/client-export/${CLIENT}/passphrase
                touch $passphrase_file
                echo "${PASSPHRASES[$CLIENT]}">>$passphrase_file
                cp $PKI_DIR/ta.key $PKI_DIR/client-export/${CLIENT}
                cp $PKI_DIR/ca.crt $PKI_DIR/client-export/${CLIENT}
                cp $PKI_DIR/issued/${CLIENT}.crt  $PKI_DIR/client-export/${CLIENT}
                cp $PKI_DIR/private/${CLIENT}.key  $PKI_DIR/client-export/${CLIENT}
                
        fi
    done
else 
    echo "EXISTING CERT FIND in /etc/openvpn/pki/issued/ no certificate will be generated"
fi


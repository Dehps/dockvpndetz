#!/bin/bash

#IMPORT CLIENTS AND DEFAULTS VARS
source $CONFIGFILES/client.sh
source $CONFIGFILES/default_vars.sh


# CHECK IF SERVER CERTIFRICATE PRIVATE KEY IS PRESENT
if [ ! -f "$PKI_DIR/private/${OVPN_SERVER_CN}.key" ]; then
 echo  >&2
 echo "**" >&2
 echo "The server key wasn't found, which means that something's" >&2
 echo "gone wrong with generating the certificates.  Try running" >&2
 echo "the container again with the REGENERATE_CERTS environmental" >&2
 echo "variable set to 'true'" >&2
 echo "**" >&2
 echo  >&2
 exit 1
fi

# Generate clientconfig at start
for CLIENT in "${CLIENTS[@]}"; do
    CLIENTCONFIG=$PKI_DIR/client-export/${CLIENT}/${CLIENT}.ovpn    
    touch "$CLIENTCONFIG"
    cat <<Part01 >>"$CLIENTCONFIG"
   
client
dev tun
persist-key
persist-tun
remote $OVPN_SERVER_CN $OVPN_PORT_CLIENT_SIDE $OVPN_PROTOCOL
remote-cert-tls server
auth SHA512
proto $OVPN_PROTOCOL
reneg-sec 0    
Part01

# If OVPN_ROUTES is empty (default config)
    if [ "${OVPN_ROUTES}x" == "x" ] ; then
        echo "redirect-gateway def1">>"$CLIENTCONFIG"
    fi


# Windows: this can force some windows clients to load the DNS configuration
    if [ "${OVPN_REGISTER_DNS}" == "true" ]; then 
        echo "register-dns">>"$CLIENTCONFIG"
    fi 
    
  cat <<Part02 >>"$CLIENTCONFIG"   
verb $OVPN_VERBOSITY
float
nobind
ca ca.crt
tls-auth ta.key 1        
Part02
    if [ ! -f "$PKI_DIR/private/${CLIENT}.key" ] || [ ! -f "$PKI_DIR/issued/${CLIENT}.crt" ] ; then
 
        echo Clients certificate is missing from pki check $PKI_DIR/issued/${CLIENT}.crt 
        echo certificates weren t generated.  Exiting...
        exit 1
    else 
        echo cert ${CLIENT}.crt >> "$CLIENTCONFIG"
        echo key ${CLIENT}.key >> "$CLIENTCONFIG"
        

     fi

        # Create ZIP for export to client
    zip -r $PKI_DIR/client-export/${CLIENT}.zip $PKI_DIR/client-export/${CLIENT}
done

 

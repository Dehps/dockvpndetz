CONFIG_FILE="${OVPN_DIR}/server.conf"

#CREATE Openvpn LOG DIR if not exist
if [ ! -d "$LOG_DIR" ]; then
 mkdir -p $LOG_DIR
fi

LOG_FILE="${LOG_DIR}/openvpn.log"

# Create Openvpn LOG file if not exist
if [ ! -f "$LOG_FILE" ]; then
   touch $LOG_FILE
fi
echo "openvpn: creating server config"

if [ -f $CONFIG_FILE ]; then
   rm $CONFIG_FILE
fi


echo "# OpenVPN server configuration" > $CONFIG_FILE


echo "server $OVPN_NETWORK" >> $CONFIG_FILE


cat <<Part01 >>$CONFIG_FILE

port $OVPN_PORT
proto $OVPN_PROTOCOL
dev $OVPN_INTERFACE_NAME
dev-type tun

ca $PKI_DIR/ca.crt
cert $PKI_DIR/issued/${OVPN_SERVER_CN}.crt
key $PKI_DIR/private/${OVPN_SERVER_CN}.key
dh $PKI_DIR/dh.pem

Part01

if [ "${OVPN_DNS_SERVERS}x" != "x" ] ; then

 nameservers=(${OVPN_DNS_SERVERS//,/ })
 
 for this_dns_server in "${nameservers[@]}" ; do
  echo "push \"dhcp-option DNS $this_dns_server\"" >> $CONFIG_FILE
 done

fi

if [ "${OVPN_DNS_SEARCH_DOMAIN}x" != "x" ]; then
 domains=(${OVPN_DNS_SEARCH_DOMAIN//,/ })
 for this_search_domain in "${domains[@]}" ; do
  echo "push \"dhcp-option DOMAIN $this_search_domain\"" >> $CONFIG_FILE
 done
fi

echo "compress migrate" >> $CONFIG_FILE

if [ "${OVPN_IDLE_TIMEOUT}x" != "x" ] && [ "${OVPN_IDLE_TIMEOUT##*[!0-9]*}" ] ; then
  cat <<TIMEOUTS >> $CONFIG_FILE

inactive $OVPN_IDLE_TIMEOUT
ping 10
ping-exit 60

push "inactive $OVPN_IDLE_TIMEOUT"
push "ping 10"
push "ping-exit 60"

TIMEOUTS
else
  echo -e "keepalive 10 60\n\n" >> $CONFIG_FILE
fi

if [ -f "/tmp/routes_config.txt" ]; then
  cat /tmp/routes_config.txt >> $CONFIG_FILE
fi

cat <<Part02 >>$CONFIG_FILE

# As we're using LDAP, each client can use the same certificate

tls-server
tls-auth $PKI_DIR/ta.key 0 
tls-cipher $OVPN_TLS_CIPHERS
tls-ciphersuites $OVPN_TLS_CIPHERSUITES
auth SHA512


persist-key
persist-tun

status $OVPN_DIR/openvpn-status.log
log-append $LOG_FILE
verb $OVPN_VERBOSITY

# Do not force renegotiation of client
reneg-sec 0

Part02


if [ "${OVPN_MANAGEMENT_ENABLE}" == "true" ]; then
 if [ "${OVPN_MANAGEMENT_NOAUTH}" == "true" ]; then
  if [ "${OVPN_MANAGEMENT_PASSWORD}x" != "x" ]; then
   echo "openvpn: warning: management password is set, but authentication is disabled"
  fi
  echo "management 0.0.0.0 ${OVPN_MANAGEMENT_PORT}" >> $CONFIG_FILE
  echo "openvpn: management interface enabled without authentication"
 else
  if [ "${OVPN_MANAGEMENT_PASSWORD}x" != "x" ]; then
   PW_FILE="${OVPN_DIR}/management_pw"
   echo "$OVPN_MANAGEMENT_PASSWORD" > $PW_FILE
   chmod 600 $PW_FILE
   echo "management 0.0.0.0 ${OVPN_MANAGEMENT_PORT} $PW_FILE" >> $CONFIG_FILE
   echo "openvpn: management interface enabled with authentication"
  else
   echo "openvpn: warning: management password is not set, but authentication is enabled"
   echo "openvpn: management interface disabled"
  fi
 fi
else
  echo "openvpn: management interface disabled"
fi

echo "$OVPN_EXTRA" >> $CONFIG_FILE

rm -rf /tmp/routes_config.txt
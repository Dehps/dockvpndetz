# Create the TUN device for OpenVPN if it doesn't exist
mkdir -p /dev/net
if [ ! -c /dev/net/tun ]; then
  mknod /dev/net/tun c 10 200  # Create the TUN device
fi

# Extract the network address and CIDR notation from the OVPN_NETWORK variable
ovpn_net_net=$(echo ${OVPN_NETWORK} | awk '{ print $1 }')  # Get the network address
ovpn_net_cidr=$(ipcalc -nb ${OVPN_NETWORK} | grep ^Netmask | awk '{ print $NF }')  # Get the netmask in CIDR
ovpn_net="${ovpn_net_net}/${ovpn_net_cidr}"  # Combine them into CIDR format

# Determine the default NAT device (the interface for outgoing traffic)
export this_natdevice=$(route | grep '^default' | grep -o '[^ ]*$')

# Check if OVPN_ROUTES is set to configure routes to push to clients
if [ "${OVPN_ROUTES}x" != "x" ]; then
  IFS=","  # Set internal field separator to comma for route parsing
  read -r -a route_list <<<"$OVPN_ROUTES"  # Read routes into an array

  echo "" >/tmp/routes_config.txt  # Clear the routes configuration file

  # Loop through each route specified in OVPN_ROUTES
  for this_route in ${route_list[@]}; do
    echo "routes: adding route $this_route to server config"  # Log the route addition
    echo "push \"route $this_route\"" >>/tmp/routes_config.txt  # Add route to the config file

    # If NAT is enabled, set up iptables rules for the route
    if [ "$OVPN_NAT" == "true" ]; then
      IFS=" "  # Reset internal field separator for space
      this_net=$(echo $this_route | awk '{ print $1 }')  # Get the network part of the route
      this_cidr=$(ipcalc -nb $this_route | grep ^Netmask | awk '{ print $NF }')  # Get the CIDR for the route
      IFS=","  # Reset separator back to comma
      to_masquerade="${this_net}/${this_cidr}"  # Combine into CIDR format

      # Log and create the iptables rule for masquerading
      echo "iptables: masquerade from $ovpn_net to $to_masquerade via $this_natdevice"
      echo -n "iptables: "
      if iptables -t nat -C POSTROUTING -s "$ovpn_net" -d "$to_masquerade" -o "$this_natdevice" -j MASQUERADE > /dev/null 2>&1; then
        echo "Rule already present. Skipping..."  # Rule exists, skip creation
      else
        echo "Rule missing. Creating rule..."  # Create the rule if it doesn't exist
        iptables -t nat -A POSTROUTING -s "$ovpn_net" -d "$to_masquerade" -o "$this_natdevice" -j MASQUERADE
      fi
    fi
  done

  IFS=" "  # Reset IFS back to space for any further processing
else
  # If no specific routes are set, redirect all client traffic over the tunnel
  echo "push \"redirect-gateway def1\"" >>/tmp/routes_config.txt

  # If NAT is enabled, set up a default masquerade rule for all traffic
  if [ "$OVPN_NAT" == "true" ]; then
    echo "iptables: masquerade from $ovpn_net to everywhere via $this_natdevice"
    echo -n "iptables: "
    if iptables -t nat -C POSTROUTING -s "$ovpn_net" -o "$this_natdevice" -j MASQUERADE > /dev/null 2>&1; then
      echo "Rule already present. Skipping..."  # Rule exists, skip creation
    else
      echo "Rule missing. Creating rule..."  # Create the rule if it doesn't exist
      iptables -t nat -A POSTROUTING -s "$ovpn_net" -o "$this_natdevice" -j MASQUERADE
    fi
  fi
fi

# Append extra iptables rules from a specified file if provided
if [ "${IPTABLES_EXTRA_FILE}x" != "x" ]; then
  if [ -f "$IPTABLES_EXTRA_FILE" ]; then
    echo "IPTABLES_EXTRA_FILE was set, appending iptables rules from $IPTABLES_EXTRA_FILE"
    iptables-restore -nv "$IPTABLES_EXTRA_FILE"  # Restore rules from the specified file
  else
    echo "IPTABLES_EXTRA_FILE was set but the specified file $IPTABLES_EXTRA_FILE cannot be found!"  # Handle missing file
  fi
fi

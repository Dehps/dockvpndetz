
declare -A PASSPHRASES


if [ -n "$USERS" ]; then
    IFS=',' read -r -a CLIENTS <<< "$USERS"
else
    declare -a CLIENTS=("Client1" "toto")
fi

# Function to generate a random passphrase,passphrase will be print in passphrase file>
generate_passphrase() {
    # Generate a random 12-character alphanumeric passphrase
    openssl rand -base64 12 | tr -dc 'A-Za-z0-9' | head -c 12
}

# Set random passphrases based on CLIENTS array
for client in "${CLIENTS[@]}"; do
    PASSPHRASES["$client"]=$(generate_passphrase)
done


# OR SET PASSPHRASE MANUALLY
# PASSPHRASES["Client1"]="passphrase_for_client1"
# PASSPHRASES["toto"]="passphrase_for_toto"

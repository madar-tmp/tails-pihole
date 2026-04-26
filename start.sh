#!/bin/sh
# made By Surya...!!!

# Create the state directory so Tailscale doesn't throw a missing folder warning
mkdir -p /var/lib/tailscale

echo "Starting Tailscale daemon in userspace mode..."
# Run tailscaled in the background with userspace networking
tailscaled --tun=userspace-networking --socks5-server=localhost:1055 &

# Give the daemon 5 seconds to initialize
sleep 5

# Authenticate Tailscale
if [ -n "$TAILSCALE_AUTHKEY" ]; then
    echo "Authenticating Tailscale node..."
    tailscale up --authkey="${TAILSCALE_AUTHKEY}" --ssh --hostname=render-pihole --accept-dns=false
else
    echo "CRITICAL ERROR: TAILSCALE_AUTH_KEY environment variable is missing!"
    exit 1
fi

echo "Starting cloudflared proxy for DNS-over-HTTPS..."
# Run cloudflared in the background. It will listen on port 5053 
# and encrypt queries before sending them to 1.1.1.1 and 9.9.9.9
cloudflared proxy-dns --port 5053 --upstream https://1.1.1.1/dns-query --upstream https://9.9.9.9/dns-query &

echo "Running native Pi-hole v6 boot sequence..."
# Run the Pi-hole start script in the background
/usr/bin/start.sh &

# --- NEW ADLIST INJECTION LOGIC ---
echo "Waiting 20 seconds for Pi-hole to create its initial databases..."
sleep 20

echo "Injecting custom adlists from GitHub into Pi-hole..."
# Read the adlists.txt file line by line
while IFS= read -r url || [ -n "$url" ]; do
    # Skip empty lines
    if [ -n "$url" ]; then
        # Use sqlite3 to safely insert the URL into the gravity database.
        # INSERT OR IGNORE prevents errors if the URL is already in the database.
        sqlite3 /etc/pihole/gravity.db "INSERT OR IGNORE INTO adlist (address, enabled, comment) VALUES ('$url', 1, 'Custom Surya List');"
    fi
done < /adlists.txt

echo "Updating Pi-hole Gravity to activate new adlists..."
# Run the gravity update to pull down all the blocked domains
pihole -g
# ----------------------------------

# Hold the container open forever so Docker doesn't think it exited
echo "Initialization complete. Tailing Pi-hole logs..."
tail -f /var/log/pihole/pihole.log /var/log/pihole/FTL.log

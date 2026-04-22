#!/bin/sh

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

echo "Running native Pi-hole v6 boot sequence..."
# Run the Pi-hole start script in the background
/usr/bin/start.sh &

# Hold the container open forever so Docker doesn't think it exited
echo "Initialization complete. Tailing Pi-hole logs..."
tail -f /var/log/pihole/pihole.log /var/log/pihole/FTL.log

#!/bin/sh

# Create the state directory so Tailscale doesn't throw a missing folder warning
mkdir -p /var/lib/tailscale

# 1. BIND THE DUMMY SERVER TO THE PUBLIC INTERFACE
# We grab Render's injected port (8000) and explicitly bind to 0.0.0.0
# This absorbs all public traffic from tails-pihole.onrender.com
RENDER_PORT=${PORT:-8000}
echo "Starting dummy public web server on port $RENDER_PORT..."
busybox httpd -p 0.0.0.0:$RENDER_PORT -h /var/www/web

# 2. BIND PI-HOLE STRICTLY TO LOCALHOST (THE FIX)
# By specifying 127.0.0.1, Pi-hole becomes completely invisible to Render's edge router 
# and the public internet. Only internal container processes (like Tailscale) can reach it.
export FTLCONF_webserver_port="127.0.0.1:8080"

echo "Starting Tailscale daemon in userspace mode..."
# Run tailscaled in the background with userspace networking
tailscaled --tun=userspace-networking --socks5-server=localhost:1055 &

# Give the daemon 5 seconds to initialize
sleep 5

# Authenticate Tailscale
if [ -n "$TAILSCALE_AUTHKEY" ]; then
    echo "Authenticating Tailscale node..."
    tailscale up --authkey="${TAILSCALE_AUTHKEY}" --ssh --hostname=tails-pihole --accept-dns=false
else
    echo "CRITICAL ERROR: TAILSCALE_AUTH_KEY environment variable is missing!"
    exit 1
fi

echo "Starting cloudflared proxy for DNS-over-HTTPS..."
# Run cloudflared in the background.
cloudflared proxy-dns --port 5053 --upstream https://1.1.1.1/dns-query --upstream https://9.9.9.9/dns-query &

echo "Running native Pi-hole boot sequence..."
# Strip the PORT variable so Pi-hole doesn't try to override our localhost command
env -u PORT /usr/bin/start.sh &

# Hold the container open forever so Docker doesn't think it exited
echo "Initialization complete. Tailing Pi-hole logs..."
tail -f /var/log/pihole/pihole.log /var/log/pihole/FTL.log

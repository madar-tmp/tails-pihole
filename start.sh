#!/bin/sh

# Create the state directory so Tailscale doesn't throw a missing folder warning
mkdir -p /var/lib/tailscale

# Force Pi-hole v6 to run its admin dashboard on port 8080 instead of 80.
# This keeps it completely hidden from Render's public URL router.
export FTLCONF_webserver_port="8080"

# Render uses the $PORT environment variable to route public web traffic.
# We bind our fake server to this port so it absorbs all public visitors.
PUBLIC_PORT=${PORT:-80}
echo "Starting public web server on port $PUBLIC_PORT..."
busybox httpd -p $PUBLIC_PORT -h /var/www/web

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

echo "Running native Pi-hole v6 boot sequence on port 8080..."
# Run the Pi-hole start script in the background
/usr/bin/start.sh &

# Hold the container open forever so Docker doesn't think it exited
echo "Initialization complete. Tailing Pi-hole logs..."
tail -f /var/log/pihole/pihole.log /var/log/pihole/FTL.log

#!/bin/sh

# Create the state directory so Tailscale doesn't throw a missing folder warning
mkdir -p /var/lib/tailscale

# 1. CAPTURE RENDER'S PUBLIC PORT
# We grab Render's injected port (8000) before Pi-hole can see it.
PUBLIC_PORT=${PORT:-8000}

echo "Starting dummy public web server on port $PUBLIC_PORT..."
# Bind the dummy server explicitly to 0.0.0.0 on the public port
busybox httpd -f -p 0.0.0.0:$PUBLIC_PORT -h /var/www/web &

# 2. THE MAGIC FIX: DESTROY THE PORT VARIABLE
# By wiping this variable from existence, Pi-hole can't hijack Render's public router.
unset PORT

# 3. FORCE PI-HOLE INTO HIDING
# Set both v5 and v6 port variables to 8080 just to be absolutely bulletproof.
export FTLCONF_webserver_port="8080"
export WEB_PORT="8080"

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

echo "Running native Pi-hole boot sequence on port 8080..."
# Run the Pi-hole start script in the background
/usr/bin/start.sh &

# Hold the container open forever so Docker doesn't think it exited
echo "Initialization complete. Tailing Pi-hole logs..."
tail -f /var/log/pihole/pihole.log /var/log/pihole/FTL.log

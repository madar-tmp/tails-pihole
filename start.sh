#!/bin/sh

echo "Starting Tailscale daemon in userspace mode..."
# Render containers are unprivileged, so we MUST use userspace networking
tailscaled --tun=userspace-networking --socks5-server=localhost:1055 &

# Wait a few seconds for the daemon to initialize
sleep 5

# Authenticate Tailscale using the environment variable
if [ -n "$TAILSCALE_AUTHKEY" ]; then
    echo "Authenticating Tailscale..."
    tailscale up --authkey="${TAILSCALE_AUTHKEY}" --hostname=render-pihole --ssh --accept-dns=false
else
    echo "ERROR: TAILSCALE_AUTHKEY environment variable is missing!"
fi

echo "Handing over to native Pi-hole v6 boot sequence..."
# exec replaces the current process with Pi-hole's native v6 entrypoint
exec /start.sh

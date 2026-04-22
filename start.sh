#!/bin/bash

echo "Starting Tailscale daemon in userspace mode..."
# Render containers are unprivileged, so we MUST use userspace networking
tailscaled --tun=userspace-networking --socks5-server=localhost:1055 &

# Wait a few seconds for the daemon to initialize
sleep 5

# Authenticate Tailscale using the environment variable
if [ -n "$TAILSCALE_AUTHKEY" ]; then
    echo "Authenticating Tailscale..."
    # --accept-dns=false prevents Tailscale from overriding Pi-hole's internal DNS routing
    tailscale up --authkey="${TAILSCALE_AUTHKEY}" --hostname=render-pihole --ssh --accept-dns=false
else
    echo "ERROR: TAILSCALE_AUTHKEY environment variable is missing!"
fi

echo "Handing over to Pi-hole s6-overlay init system..."
# exec replaces the current bash process with Pi-hole's init, keeping the container alive
exec /s6-init

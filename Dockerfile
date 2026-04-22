FROM pihole/pihole:latest

# Pi-hole v6 uses Alpine Linux, so we must use 'apk' to install packages
RUN apk update && apk add --no-cache curl tailscale

# Copy the custom initialization script
COPY start.sh /custom-start.sh
RUN chmod +x /custom-start.sh

# Expose port 80 so Render can route the web admin dashboard
EXPOSE 80

# Override the default entrypoint to run our script first
ENTRYPOINT ["/custom-start.sh"]

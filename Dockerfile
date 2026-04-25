FROM pihole/pihole:latest

# Pi-hole v6 uses Alpine Linux. Add sqlite to interact with the database.
RUN apk update && apk add --no-cache curl tailscale sqlite

# Copy your custom adlists file from GitHub into the container
COPY adlists.txt /adlists.txt

# Copy the custom initialization script
COPY start.sh /custom-start.sh
RUN chmod +x /custom-start.sh

# Expose port 80 so Render can route the web admin dashboard
EXPOSE 80

# Override the default entrypoint to run our script first
ENTRYPOINT ["/custom-start.sh"]

FROM pihole/pihole:latest

# Update packages and install Tailscale
RUN apt-get update && apt-get install -y curl && \
    curl -fsSL https://tailscale.com/install.sh | sh && \
    rm -rf /var/lib/apt/lists/*

# Copy the custom initialization script
COPY start.sh /start.sh
RUN chmod +x /start.sh

# Expose port 80 so Render can route the web admin dashboard
EXPOSE 80

# Override the default entrypoint to run our script first
ENTRYPOINT ["/start.sh"]

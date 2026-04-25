FROM pihole/pihole:latest

# Pi-hole v6 uses Alpine Linux, so we must use 'apk' to install packages
RUN apk update && apk add --no-cache curl tailscale

# Download and install cloudflared for DNS-over-HTTPS encryption
RUN curl -L -o /usr/local/bin/cloudflared https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 && \
    chmod +x /usr/local/bin/cloudflared

# Create a web web directory and a fake index.html for public visitors
RUN mkdir -p /var/www/web && \
    echo "<html><head><title>404 Not Found</title></head><body style='background:#f4f4f4; text-align:center; padding-top:100px; font-family:sans-serif; color:#333;'><h1>404 - Not Found</h1><p>The requested resource could not be found on this server.</p></body></html>" > /var/www/web/index.html

# Copy the custom initialization script
COPY start.sh /custom-start.sh
RUN chmod +x /custom-start.sh

# Expose port 80 for Render (which will serve the public web page)
# Expose port 8080 for your private Tailnet Pi-hole access
EXPOSE 80
EXPOSE 8080

# Override the default entrypoint to run our script first
ENTRYPOINT ["/custom-start.sh"]

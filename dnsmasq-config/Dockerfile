# Use a well-maintained dnsmasq image as base
FROM dockurr/dnsmasq:latest

# Install vim and keep the image minimal
RUN apk update && apk add --no-cache vim bash

# Create directory for custom configs (if not exists)
RUN mkdir -p /etc/dnsmasq.d

# Set default upstream DNS via environment variables
ENV DNS1=1.1.1.1
ENV DNS2=8.8.8.8

# The base image's entrypoint already handles:
# 1. Processing environment variables to config
# 2. Starting dnsmasq in foreground
# 3. Proper signal handling

# No need to override CMD or ENTRYPOINT - base image handles it
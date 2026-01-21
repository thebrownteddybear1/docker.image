FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive

# Install dnsmasq and network utilities
RUN apt-get update && apt-get install -y \
    dnsmasq \
    dnsutils \
    iputils-ping \
    net-tools \
    && rm -rf /var/lib/apt/lists/*

# Create directory for custom configs
RUN mkdir -p /etc/dnsmasq.d

# Copy configuration files
COPY config/dnsmasq.conf /etc/dnsmasq.conf
COPY config/hosts.custom /etc/hosts.custom

# Create startup script
RUN echo '#!/bin/bash\n\
# Set permissions\n\
chmod 644 /etc/dnsmasq.conf /etc/hosts.custom 2>/dev/null || true\n\
# Test configuration\n\
echo "Testing dnsmasq configuration..."\n\
dnsmasq --test\n\
# Start dnsmasq in foreground\n\
echo "Starting dnsmasq for corp.internal domain..."\n\
exec dnsmasq -k --log-facility=-\n' > /start.sh && \
    chmod +x /start.sh

# Expose DNS port
EXPOSE 53/udp 53/tcp

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD dig @127.0.0.1 dns.corp.internal || exit 1

# Start dnsmasq
ENTRYPOINT ["/start.sh"]
FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive

# Install dnsmasq + DNS testing tools only (no logging packages)
RUN apt-get update && apt-get install -y \
    dnsmasq \
    dnsutils && \
    rm -rf /var/lib/apt/lists/*

# Copy configuration files
COPY config/dnsmasq.conf /etc/dnsmasq.conf
COPY config/hosts.custom /etc/hosts.custom

# Minimal startup script (no logging)
RUN echo '#!/bin/bash\nexec dnsmasq -k\n' > /start.sh && \
    chmod +x /start.sh

EXPOSE 53/udp 53/tcp

ENTRYPOINT ["/start.sh"]
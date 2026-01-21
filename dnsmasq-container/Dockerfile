FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    dnsmasq \
    dnsutils \
    iputils-ping \
    net-tools \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /etc/dnsmasq.d

COPY config/dnsmasq.conf /etc/dnsmasq.conf
COPY config/hosts.custom /etc/hosts.custom

RUN echo '#!/bin/bash\n\
set -x\n\
echo "Testing dnsmasq configuration..."\n\
dnsmasq --test || exit 1\n\
echo "Starting dnsmasq for corp.internal domain..."\n\
# Run dnsmasq in foreground with debug logging\n\
exec dnsmasq -k --log-facility=- --log-debug\n' > /start.sh && \
    chmod +x /start.sh

EXPOSE 53/udp 53/tcp

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD dig @127.0.0.1 dns.corp.internal || exit 1

ENTRYPOINT ["/start.sh"]
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Install required packages and FRR
RUN apt-get update && apt-get install -y \
    iproute2 \
    vlan \
    kmod \
    net-tools \
    iputils-ping \
    curl \
    frr \
    frr-pythontools \
    systemd \
    && rm -rf /var/lib/apt/lists/*

# Enable IP forwarding in kernel
RUN echo "net.ipv4.conf.all.forwarding=1" >> /etc/sysctl.conf && \
    echo "net.ipv6.conf.all.forwarding=1" >> /etc/sysctl.conf

# Create FRR configuration directory
RUN mkdir -p /etc/frr

# Copy configuration files
COPY frr.conf /etc/frr/frr.conf
COPY daemons /etc/frr/daemons

# Set correct permissions
RUN chown -R frr:frr /etc/frr && \
    chmod 640 /etc/frr/frr.conf

# Copy startup script
COPY startup.sh /startup.sh
RUN chmod +x /startup.sh

# Set entrypoint
ENTRYPOINT ["/bin/bash", "/startup.sh"]
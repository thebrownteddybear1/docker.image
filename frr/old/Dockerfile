FROM frrouting/frr:latest

# Install additional packages for VLAN setup
RUN apt-get update && apt-get install -y \
    iproute2 \
    vlan \
    kmod \
    net-tools \
    && rm -rf /var/lib/apt/lists/*

# Copy our custom configuration
COPY frr.conf /etc/frr/frr.conf
COPY daemons /etc/frr/daemons

# Copy startup script
COPY startup.sh /startup.sh
RUN chmod +x /startup.sh

# Set correct permissions for FRR files
RUN chown -R frr:frr /etc/frr

# Set entrypoint to our startup script
ENTRYPOINT ["/startup.sh"]
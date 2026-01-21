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
    lsb-release \
    frr \
    frr-pythontools \
    && rm -rf /var/lib/apt/lists/*

# Enable IP forwarding in kernel
RUN echo "net.ipv4.conf.all.forwarding=1" >> /etc/sysctl.conf && \
    echo "net.ipv6.conf.all.forwarding=1" >> /etc/sysctl.conf

# Copy configuration files
COPY frr.conf /etc/frr/frr.conf
COPY startup.sh /startup.sh

# Enable zebra and bgpd in daemons file
RUN sed -i 's/zebra=no/zebra=yes/g' /etc/frr/daemons && \
    sed -i 's/bgpd=no/bgpd=yes/g' /etc/frr/daemons

# Set correct permissions
RUN chown -R frr:frr /etc/frr && \
    chmod 640 /etc/frr/frr.conf && \
    chmod +x /startup.sh

# Set entrypoint
ENTRYPOINT ["/bin/bash", "/startup.sh"]
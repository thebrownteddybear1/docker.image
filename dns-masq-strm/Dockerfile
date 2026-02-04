# Use Ubuntu 24.04 to get Dnsmasq v2.90+
FROM ubuntu:24.04

# Install dnsmasq and clean up to keep the image small
RUN apt-get update && apt-get install -y \
    dnsmasq \
    && rm -rf /var/lib/apt/lists/*

# Create the lease file directory (required for DHCP/Lease tracking)
RUN touch /var/lib/misc/dnsmasq.leases

# DNS runs on port 53 (UDP and TCP)
EXPOSE 53/udp
EXPOSE 53/tcp

# -k keeps dnsmasq in the foreground so the container doesn't exit
ENTRYPOINT ["dnsmasq", "-k"]
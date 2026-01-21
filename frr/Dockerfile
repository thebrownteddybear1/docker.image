FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Install required packages and FRR
RUN apt-get update && apt-get install -y \
    wget \
    gnupg2 \
    software-properties-common \
    iproute2 \
    vlan \
    kmod \
    net-tools \
    iputils-ping \
    curl \
    lsb-release \
    && rm -rf /var/lib/apt/lists/*

# Add FRR repository and install FRR
RUN apt-get update && \
    apt-get install -y curl && \
    curl -s https://deb.frrouting.org/frr.asc | apt-key add - && \
    echo "deb https://deb.frrouting.org/frr $(lsb_release -s -c) frr-stable" > /etc/apt/sources.list.d/frr.list && \
    apt-get update && apt-get install -y frr frr-pythontools

# Enable IP forwarding in kernel
RUN echo "net.ipv4.conf.all.forwarding=1" >> /etc/sysctl.conf && \
    echo "net.ipv6.conf.all.forwarding=1" >> /etc/sysctl.conf

# Create FRR configuration directory
RUN mkdir -p /etc/frr

# Create frr.conf with the provided configuration
RUN echo '!
frr defaults traditional
hostname ubuntu
log syslog informational
service integrated-vtysh-config
!
debug zebra events
debug zebra packet
debug zebra kernel
debug zebra rib detailed
debug zebra nht
debug zebra dplane detailed
debug zebra dplane dpdk detailed
debug zebra nexthop
!
password frr
enable password frr
!
exit
!
router bgp 65001
 bgp router-id 10.11.11.53
 no bgp ebgp-requires-policy
 neighbor 10.11.11.253 remote-as 65002
 neighbor 10.11.11.253 disable-connected-check
 neighbor 10.11.11.253 timers connect 10
 !
 address-family ipv4 unicast
  network 192.168.50.0/24
  redistribute connected
  redistribute static
  neighbor 10.11.11.253 next-hop-self
  neighbor 10.11.11.253 soft-reconfiguration inbound
  neighbor 10.11.11.253 prefix-list allowed in
  neighbor 10.11.11.253 prefix-list allowed out
 exit-address-family
exit
!
ip prefix-list allowed seq 5 permit any
!
ip nht resolve-via-default
!
end' > /etc/frr/frr.conf

# Enable zebra and bgpd in daemons file
RUN echo '#
# FRRouting daemons configuration file
#
# The watchdog and zebra daemons are always started.
#
watchfrr_enable=yes
watchfrr_options="-r '/usr/lib/frr/frr restart %s' -s '/usr/lib/frr/frr start %s' -k '/usr/lib/frr/frr stop %s"'
#
# If this option is set the /etc/init.d/frr script automatically loads
# the config via "vtysh -b" when the servers are started.
# Check /etc/pam.d/frr if you intend to use "vtysh"!
#
vtysh_enable=yes
zebra=yes
bgpd=yes
ospfd=no
ospf6d=no
ripd=no
ripngd=no
isisd=no
pimd=no
ldpd=no
nhrpd=no
eigrpd=no
babeld=no
sharpd=no
pbrd=no
bfdd=no
fabricd=no
vrrpd=no' > /etc/frr/daemons

# Set correct permissions for FRR files
RUN chown -R frr:frr /etc/frr && \
    chmod 640 /etc/frr/frr.conf

# Create a startup script that properly loads the config
RUN echo '#!/bin/bash

# Load 802.1q module on the host (requires privileged container)
modprobe 8021q

# Create VLAN interface on ens33
ip link add link ens33 name ens33.11 type vlan id 11

# Bring up the VLAN interface
ip link set ens33.11 up

# Assign IP address to VLAN interface
ip addr add 10.11.11.53/24 dev ens33.11

# Enable IP forwarding (already in sysctl.conf, but apply again)
sysctl -w net.ipv4.conf.all.forwarding=1
sysctl -w net.ipv6.conf.all.forwarding=1

# Start FRR daemons manually to ensure config is loaded
/usr/lib/frr/frrinit.sh start

# Wait a moment for daemons to start
sleep 2

# Check if FRR is running
if vtysh -c "show running-config" > /dev/null 2>&1; then
    echo "FRR is running with configuration"
    vtysh -c "show running-config"
else
    echo "FRR is not running properly"
    # Try to start manually
    zebra -d
    bgpd -d
    sleep 2
fi

# Keep container running
tail -f /dev/null' > /startup.sh

RUN chmod +x /startup.sh

# Set entrypoint
ENTRYPOINT ["/bin/bash", "/startup.sh"]
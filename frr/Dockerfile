FROM ubuntu:latest

ENV DEBIAN_FRONTEND=noninteractive

# Install required packages and FRR from Ubuntu repositories
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
    frr \
    frr-pythontools \
    && rm -rf /var/lib/apt/lists/*

# Enable IP forwarding in kernel
RUN echo "net.ipv4.conf.all.forwarding=1" >> /etc/sysctl.conf && \
    echo "net.ipv6.conf.all.forwarding=1" >> /etc/sysctl.conf

# Create FRR configuration directory
RUN mkdir -p /etc/frr

# Create frr.conf with the provided configuration
RUN cat << 'EOF' > /etc/frr/frr.conf
!
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
end
EOF

# Enable zebra and bgpd in daemons file
RUN sed -i 's/^zebra=no/zebra=yes/' /etc/frr/daemons && \
    sed -i 's/^bgpd=no/bgpd=yes/' /etc/frr/daemons

# Set a simple command that will start everything
CMD /bin/bash -c "modprobe 8021q && \
    ip link add link ens33 name ens33.11 type vlan id 11 && \
    ip link set ens33.11 up && \
    ip addr add 10.11.11.53/24 dev ens33.11 && \
    sysctl -w net.ipv4.conf.all.forwarding=1 && \
    sysctl -w net.ipv6.conf.all.forwarding=1 && \
    /usr/lib/frr/frrinit.sh start && \
    tail -f /dev/null"
#!/bin/bash

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

# Start FRR daemons
systemctl restart frr.service
# or on some systems:
service frr restart


# Keep container running
tail -f /dev/null
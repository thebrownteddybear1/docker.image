#!/bin/bash

# Clean up any existing watchfrr temporary directories
rm -rf /var/tmp/frr/watchfrr.* 2>/dev/null || true

# Load 802.1q module
modprobe 8021q

# Remove existing VLAN interface if it exists
ip link delete ens33.11 2>/dev/null || true

# Create VLAN interface on ens33
ip link add link ens33 name ens33.11 type vlan id 11
ip link set ens33.11 up
ip addr add 10.11.11.53/24 dev ens33.11

# Create VLAN interface on ens33
ip link add link ens33 name ens33.51 type vlan id 51
ip link set ens33.51 up
ip addr add 192.168.51.53/24 dev ens33.51


# Create VLAN interface on ens33
ip link add link ens33 name ens33.52 type vlan id 52
ip link set ens33.52 up
ip addr add 192.168.52.53/24 dev ens33.52


# Enable IP forwarding
sysctl -w net.ipv4.conf.all.forwarding=1
sysctl -w net.ipv6.conf.all.forwarding=1

# Create vtysh.conf if it doesn't exist
if [ ! -f /etc/frr/vtysh.conf ]; then
    touch /etc/frr/vtysh.conf
    chown frr:frr /etc/frr/vtysh.conf
    chmod 640 /etc/frr/vtysh.conf
fi

# Start FRR using the image's default startup script
exec /usr/lib/frr/docker-start
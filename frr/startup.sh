#!/bin/bash

# Load 802.1q module on the host (requires privileged container)
modprobe 8021q || echo "8021q module loaded or already loaded"

# Remove existing VLAN interface if it exists
if ip link show ens33.11 > /dev/null 2>&1; then
    echo "Removing existing VLAN interface ens33.11"
    ip link delete ens33.11
    sleep 1
fi

# Create VLAN interface on ens33
echo "Creating VLAN interface ens33.11"
ip link add link ens33 name ens33.11 type vlan id 11

# Bring up the VLAN interface
ip link set ens33.11 up

# Assign IP address to VLAN interface
ip addr add 10.11.11.53/24 dev ens33.11

# Enable IP forwarding
echo "Enabling IP forwarding"
sysctl -w net.ipv4.conf.all.forwarding=1
sysctl -w net.ipv6.conf.all.forwarding=1

# Start FRR using watchfrr in daemon mode
echo "Starting FRR with watchfrr"
/usr/lib/frr/frrinit.sh start

# Wait for FRR to start
sleep 3

# Check if FRR is running
if vtysh -c "show running-config" > /dev/null 2>&1; then
    echo "FRR is running with configuration"
    echo "=== FRR Configuration ==="
    vtysh -c "show running-config" | head -20
    echo "..."
else
    echo "ERROR: FRR is not running properly"
    echo "Trying to start daemons manually..."
    
    # Start zebra and bgpd directly if watchfrr failed
    zebra -d -A 127.0.0.1 -s 90000000
    bgpd -d -A 127.0.0.1
    sleep 3
fi

# Start watchfrr in foreground to manage FRR daemons
echo "Starting watchfrr in foreground to manage FRR daemons..."
exec /usr/lib/frr/watchfrr -d
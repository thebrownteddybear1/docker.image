#!/bin/bash
echo "=== Current NFS Throughput (Precise) ==="
echo "Time: $(date)"
echo ""

# Get all NFS connections and their rates
ss -tin sport = :2049 | grep -E "(delivery_rate|send.*bps|192\.168\.52)" | while read line; do
    if echo "$line" | grep -q "192\.168\.52"; then
        IP=$(echo "$line" | grep -o "192\.168\.52\.[0-9]*")
        echo "Client $IP:"
    elif echo "$line" | grep -q "delivery_rate"; then
        RATE=$(echo "$line" | grep -o "delivery_rate [0-9]*" | awk '{print $2}')
        MBPS=$(echo "scale=2; $RATE / 8000000" | bc)
        echo "  Delivery: $MBPS MB/s ($RATE bps)"
    elif echo "$line" | grep -q "send.*bps"; then
        RATE=$(echo "$line" | grep -o "send [0-9]*" | awk '{print $2}')
        MBPS=$(echo "scale=2; $RATE / 8000000" | bc)
        echo "  Sending:  $MBPS MB/s ($RATE bps)"
    fi
done
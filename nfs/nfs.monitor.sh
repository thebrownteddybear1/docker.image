#!/bin/bash
echo "================================================================"
echo "      NFS SERVER STATUS: 512 THREADS | 100GB RAM"
echo "================================================================"

# 1. THREAD CHECK
echo -e "\n[1] THREAD POOL STATUS"
# Fixed the redirect typo here
MAX_TH=$(cat /proc/fs/nfsd/threads 2>/dev/null)
ACT_TH=$(awk '/th/ {print $2}' /proc/net/rpc/nfsd 2>/dev/null)
echo "Max Allowed Threads: $MAX_TH"
echo "Active Workers Now:  $ACT_TH"

# 2. RAM & CACHE CHECK
echo -e "\n[2] MEMORY & WRITE BUFFER"
sysctl vm.dirty_ratio vm.dirty_background_ratio
free -h | awk '/^Mem:/ {print "Total RAM: "$2 " | Available: "$7}'

# 3. MOUNT & DISK CHECK
echo -e "\n[3] XFS DISK UTILIZATION"
df -h | grep -E 'Filesystem|nfs'

# 4. EXPORT CONFIG
echo -e "\n[4] EXPORT CONFIG (Checking for 'async')"
cat /etc/exports

# 5. NETWORK PERFORMANCE
echo -e "\n[5] NETWORK PERFORMANCE (RTT/MSS)"
if ss -ntip state established | grep -q ":2049"; then
    ss -ntip state established '( dport = :2049 or sport = :2049 )' | grep -E "mss|rtt"
else
    echo "No active client traffic detected."
fi
echo -e "\n================================================================"
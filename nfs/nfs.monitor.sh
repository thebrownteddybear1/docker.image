#!/bin/bash
echo -e "\n================================================================"
echo "      NFS SERVER STATUS: 512 THREADS | 100GB RAM"
echo "================================================================"

# [1] THREAD POOL STATUS
MAX_THREADS=$(cat /proc/net/rpc/nfsd 2>/dev/null | awk '/th/ {print $2}')
echo -e "\n[1] THREAD POOL STATUS"
echo "Max Allowed Threads: ${MAX_THREADS:-512}"

# [2] MEMORY & WRITE BUFFER
echo -e "\n[2] MEMORY & WRITE BUFFER"
grep -E "dirty_ratio|dirty_background_ratio" /etc/sysctl.conf | sed 's/^/  /'
free -h | awk '/Mem:/ {print "  Total RAM: "$2" | Available: "$7}'

# [3] XFS DISK UTILIZATION
echo -e "\n[3] XFS DISK UTILIZATION"
df -h | grep -E "nfs|Filesystem" | sed 's/^/  /'

# [4] EXPORT CONFIG
echo -e "\n[4] EXPORT CONFIG (Checking for 'async')"
grep "async" /etc/exports | sed 's/^/  /'

# [5] NETWORK PERFORMANCE (RTT/MSS)
echo -e "\n[5] ACTIVE NETWORK STATS (RTT)"
STATS=$(ss -ntip state established '( dport = :2049 or sport = :2049 )')
if [ -z "$STATS" ]; then
    echo "  No active client traffic detected."
else
    echo "$STATS" | grep -E "192.168|rtt:" | sed 's/^/  /'
fi

# [6] BUSY OR STUCK WORKERS (Excluding Idle 'I' state)
echo -e "\n[6] BUSY/STUCK WORKERS (Filtering out Idle)"
BUSY_THREADS=$(ps -eo pid,user,stat,pcpu,comm | grep "[n]fsd" | grep -v " I ")
if [ -z "$BUSY_THREADS" ]; then
    echo "  All 512 threads are currently Idle (Ready)."
else
    echo "$BUSY_THREADS" | sed 's/^/  /'
fi

echo -e "\n================================================================"
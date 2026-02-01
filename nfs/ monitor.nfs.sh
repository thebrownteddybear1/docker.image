echo "NFS Server Utilization Dashboard"
echo "Time: $(date)"
echo "======================================"
echo ""

echo "1. THREAD UTILIZATION:"
echo "----------------------"
nfsd_threads=$(ps -eLf | grep nfsd | grep -v grep | wc -l)
active_threads=$(ps -eL -o pcpu,comm | grep nfsd | awk '$1>0 {count++} END {print count+0}')
echo "Total threads: $nfsd_threads"
echo "Active threads: $active_threads"
echo "CPU usage per thread:"
ps -eL -o tid,pcpu,comm | grep nfsd | head -5
echo ""

echo "2. NETWORK CONNECTIONS:"
echo "-----------------------"
total_conn=$(netstat -an | grep :2049 | wc -l)
estab_conn=$(netstat -an | grep :2049 | grep ESTAB | wc -l)
echo "Total connections: $total_conn"
echo "Established connections: $estab_conn"
echo ""

echo "3. NFS OPERATIONS (last 5 sec):"
echo "-------------------------------"
nfsstat -s | grep -A10 "Server nfs" | head -15
echo ""

echo "4. DISK I/O:"
echo "------------"
iostat -x | grep -A2 "Device" | tail -3
echo ""

echo "5. MEMORY USAGE:"
echo "----------------"
free -h | head -2
echo ""

echo "6. LOAD AVERAGE:"
echo "----------------"
uptime | awk -F'load average:' '{print $2}'
echo "======================================"
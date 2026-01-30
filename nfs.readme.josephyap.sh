#!/bin/bash
set -x

sudo apt update
sudo apt -y install nfs-kernel-server
chown nobody:nogroup /mnt/nfs1
echo "/mnt/nfs1 *(rw,sync,no_root_squash,no_subtree_check)" >> /etc/exports
systemctl restart nfs-kernel-server
systemctl disable ufw
systemctl stop ufw
systemctl status ufw

#SET BOTH THE PARENT ENSI AND NFS SERVER TO TRUNK!!!

#after you change something restart nfs
# For NFSv3/NFSv4
systemctl restart nfs-server
# or
systemctl restart nfs-kernel-server

# Sometimes also need:
systemctl restart rpcbind

# Add to /etc/sysctl.conf
sudo tee -a /etc/sysctl.conf << 'EOF'

# NFS Memory Optimizations (for 96GB RAM)
# Increase NFS read/write buffers
sunrpc.max_resvport=1023
sunrpc.min_resvport=665

# Increase NFS client memory
fs.nfs.nfs_callback_nr_threads=16
fs.nfs.nfs_mountpoint_timeout=300

# More aggressive caching
vm.dirty_background_bytes=67108864  # 64MB
vm.dirty_bytes=1073741824           # 1GB
vm.dirty_expire_centisecs=6000      # 60 seconds
vm.dirty_writeback_centisecs=500    # 5 seconds

# More file handles for many clients
fs.file-max=2097152
fs.nr_open=2097152
EOF

sudo sysctl -p

# Change to 24 threads (from current 18-20)
sudo sed -i '/^\[nfsd\]/,/^\[/ s/^threads=.*/threads=24/' /etc/nfs.conf
sudo systemctl restart nfs-server
##monitor nfs
cat > /root/nfs_monitor.sh << 'EOF'
#!/bin/bash
clear
echo "======================================"
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
EOF

chmod +x /root/nfs_monitor.sh

# Run it
watch -n 2 /root/nfs_monitor.sh


cat > /root/check_memory.sh << 'EOF'
#!/bin/bash
echo "=== Memory Utilization ==="
free -h
echo ""
echo "=== Page Cache Stats ==="
grep -E "(Dirty|Writeback|Cached|Buffers|MemTotal|MemFree)" /proc/meminfo
echo ""
echo "=== Top Memory Users ==="
ps aux --sort=-%mem | head -10
EOF

chmod +x /root/check_memory.sh
/root/check_memory.sh
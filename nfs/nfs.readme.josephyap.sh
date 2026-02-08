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
sudo apt install net-tools -y
#SET BOTH THE PARENT ENSI AND NFS SERVER TO TRUNK!!!

#after you change something restart nfs
# For NFSv3/NFSv4
systemctl restart nfs-server
# or
systemctl restart nfs-kernel-server

# Sometimes also need:
systemctl restart rpcbind

# Add to /etc/sysctl.conf
# Create clean optimized configuration
sudo cp /etc/sysctl.conf /etc/sysctl.conf.backup
sudo tee /etc/sysctl.conf << 'EOF'
# ===== NFS SERVER OPTIMIZATIONS =====
# SunRPC/NFS Connection Settings
sunrpc.tcp_max_slot_table_entries=1024
sunrpc.udp_slot_table_entries=1024
sunrpc.tcp_slot_table_entries=1024
sunrpc.max_resvport=1023
sunrpc.min_resvport=665

# NFS Specific Settings
fs.nfs.nfs_callback_nr_threads=24
fs.nfs.nfs_mountpoint_timeout=300
fs.nfs.nlm_udpport=32768
fs.nfs.nlm_tcpport=32768

# ===== NETWORK OPTIMIZATIONS =====
# Socket buffers for high throughput
net.core.rmem_max=67108864      # 64MB
net.core.wmem_max=67108864
net.core.rmem_default=16777216  # 16MB
net.core.wmem_default=16777216
net.core.optmem_max=16777216    # 16MB
net.core.netdev_max_backlog=10000
net.core.somaxconn=4096

# TCP buffers and behavior
net.ipv4.tcp_rmem=4096 87380 67108864
net.ipv4.tcp_wmem=4096 65536 67108864
net.ipv4.tcp_mem=8388608 12582912 16777216
net.ipv4.tcp_max_syn_backlog=4096
net.ipv4.tcp_syncookies=1
net.ipv4.tcp_fin_timeout=15
net.ipv4.tcp_tw_reuse=1
net.ipv4.tcp_slow_start_after_idle=0
net.ipv4.tcp_mtu_probing=1

# ===== VM MEMORY OPTIMIZATIONS =====
# Writeback caching (aggressive for 96GB RAM)
vm.dirty_background_bytes=67108864     # 64MB before background flush
vm.dirty_bytes=1073741824              # 1GB before forcing sync
vm.dirty_expire_centisecs=6000         # 60 seconds
vm.dirty_writeback_centisecs=500       # 5 seconds between flushes
vm.swappiness=5
vm.vfs_cache_pressure=50

# ===== FILE HANDLE LIMITS =====
fs.file-max=2097152
fs.nr_open=2097152
fs.aio-max-nr=1048576
EOF

# Apply the clean configuration
sudo sysctl -p

# On NFS server (54)
sudo sed -i '/^\[nfsd\]/,/^\[/ s/^threads=.*/threads=20/' /etc/nfs.conf
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


cat > /root/mtu_mystery.sh << EOF
#!/bin/bash
echo "=== Investigating MTU Mystery ==="
echo "Time: $(date)"
echo ""

# 1. Server MTU
echo "1. SERVER MTU:"
ip link show ens35 | grep mtu
echo ""

# 2. Test clients
echo "2. TESTING CLIENTS:"
for client in 192.168.52.131 192.168.52.132; do
    echo "Testing $client..."
    ping -c 1 -M do -s 8972 $client 2>&1 | grep -E "(bytes from|fragmentation)"
done
echo ""

# 3. Check TCP MSS
echo "3. ACTIVE TCP CONNECTIONS (MSS value):"
ss -tin sport = :2049 2>/dev/null | grep -E "(mss|192.168.52)" | head -5
echo ""

# 4. Real-time traffic sample
echo "4. CURRENT TRAFFIC (packet sizes):"
timeout 2 sudo tcpdump -i ens35 -c 5 'port 2049' 2>/dev/null | grep length
EOF
chmod +x /root/mtu_mystery.sh


## you added a disk to nfs vm

echo "- - -" | sudo tee /sys/class/scsi_host/host*/scan
lsblk
sudo mkfs.ext4 /dev/sdb
sudo mount /dev/sdb /mnt/data
To make it persistent across reboots, add an entry to /etc/fstab. First get the UUID:

blkid /dev/sdb

Then add a line in /etc/fstab:
UUID=<your-disk-uuid>  /mnt/data  ext4  defaults  0  2
Add the directory to /etc/exports:
/mnt/data  *(rw,sync,no_subtree_check)
sudo exportfs -ra


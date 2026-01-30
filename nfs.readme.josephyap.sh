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


sudo tee -a /etc/sysctl.conf << 'EOF'

# ========================================
# NFS Server Optimizations
# ========================================
# SunRPC/NFS connection settings
sunrpc.tcp_max_slot_table_entries=128
sunrpc.udp_slot_table_entries=128
fs.nfs.nlm_tcpport=32803
fs.nfs.nfs_callback_tcpport=32764
fs.nfs.nfs_callback_nr_threads=8

# Network buffers for better throughput
net.core.rmem_max=16777216
net.core.wmem_max=16777216
net.core.rmem_default=16777216
net.core.wmem_default=16777216
net.ipv4.tcp_rmem=4096 87380 16777216
net.ipv4.tcp_wmem=4096 65536 16777216

# VM settings optimized for large RAM (100GB)
vm.swappiness=10
vm.dirty_ratio=20
vm.dirty_background_ratio=5
vm.vfs_cache_pressure=50
EOF

sudo sysctl -p
sudo sed -i '/^\[nfsd\]/,/^\[/ s/^threads=.*/threads=20/' /etc/nfs.conf

systemctl restart nfs-server

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
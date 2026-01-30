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
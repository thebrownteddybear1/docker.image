#!/bin/bash
set -x

sudo apt update
sudo apt -y install nfs-kernel-server
chown nobody:nogroup /mnt/nfs1
echo "/mnt/nfs1 0.0.0.0 (rw,sync,no_root_squash,no_subtree_check)" >> /etc/exports
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
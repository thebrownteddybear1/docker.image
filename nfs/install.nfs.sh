#!/bin/bash
set -x
sudo chown nobody:nogroup /mnt/nfs1
sudo chmod 777 /mnt/nfs1
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

#remember to set noatime and discards in the fstab @!@@@@@!!!!!!
#/dev/disk/by-id/dm-uuid-LVM-W0wVx2OPQX5A7JehV6XMagigwoEMiyn7w2G378nc0eMmg6gmIqPhpy4kXOlvtdxK /mnt/nfs1 xfs defaults,noatime,nodiscard 0 1
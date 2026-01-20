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


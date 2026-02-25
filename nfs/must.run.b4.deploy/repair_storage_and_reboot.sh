#!/bin/bash
# 1. STOP TRAFFIC IMMEDIATELY
echo "Stopping NFS services to clear locks..."
systemctl stop nfs-kernel-server
systemctl stop nfs-server
sync
echo 3 > /proc/sys/vm/drop_caches
# 2. FORCE OS DISK REPAIR ON NEXT REBOOT
# This creates the trigger file for the OS/Root partition
#touch /forcefsck
echo "OS Disk set to auto-repair on next reboot."

# 3. UNMOUNT NFS TARGETS
echo "Unmounting /mnt/nfs drives..."
for mnt in /mnt/nfs1 /mnt/nfs2 /mnt/nfs3; do
    fuser -km "$mnt" # Kill any lingering processes using the mount
    umount -l "$mnt" # Lazy unmount if busy
done

# 4. RUN XFS REPAIR ON NVMe DRIVES
# We use -L to clear the log if it's corrupted from a crash
for dev in /dev/sdb /dev/sdc /dev/sdd; do
    echo "------------------------------------------"
    echo "REPAIRING: $dev"
    if ! mount | grep -q "$dev"; then
        xfs_repair -v -L "$dev"
    else
        echo "ERROR: $dev is still mounted! Skipping repair."
    fi
done

# 5. PERFORM TRIM (Good for NVMe health after repair)
echo "Optimizing SSD cells (TRIM)..."
fstrim -av

# 6. REMOUNT & VERIFY
echo "Remounting storage..."
mount -av

# 7. FINAL LOG CHECK
echo "------------------------------------------"
echo "Repair Cycle Complete."
xfs_info /mnt/nfs1 | grep "naming" && echo "NFS1: OK"
xfs_info /mnt/nfs2 | grep "naming" && echo "NFS2: OK"
xfs_info /mnt/nfs3 | grep "naming" && echo "NFS3: OK"

echo "Ready for reboot or service restart."
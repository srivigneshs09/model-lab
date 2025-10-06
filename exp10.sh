#!/bin/bash
# ------------------------------------------------------------
# Experiment 10: Storage Virtualization using LVM (Ubuntu)
# Author: Sri Vignesh S
# Date: $(date +"%d-%m-%Y")
# ------------------------------------------------------------

set -e  # Stop if any command fails

# CONFIGURATION
DISK="/dev/sdb"        # New virtual disk added in VirtualBox
VG_NAME="ubuntu-vg"    # Volume group name
LV_NAME="ubuntu-lv"    # Logical volume name
MOUNT_DIR="/mnt/lvm-demo"
LV_SIZE="5G"           # Initial LV size
EXTEND_SIZE="+2G"      # Size to extend

echo "===== EXPERIMENT 7: STORAGE VIRTUALIZATION USING LVM ====="
sleep 2

# 1. Inspect Disks
echo
echo "STEP 1: Inspecting available disks..."
lsblk
fdisk -l | grep "Disk /dev/" || true

# Check if the disk exists
if [ ! -b "$DISK" ]; then
    echo "Error: Disk $DISK not found. Please attach it first."
    exit 1
fi

# 2. Initialize Physical Volume
echo
echo "STEP 2: Initializing $DISK as a Physical Volume..."
sudo pvcreate "$DISK"

# 3. Create Volume Group
echo
echo "STEP 3: Creating Volume Group '$VG_NAME'..."
sudo vgcreate "$VG_NAME" "$DISK"

# 4. Create Logical Volume
echo
echo "STEP 4: Creating Logical Volume '$LV_NAME' (${LV_SIZE})..."
sudo lvcreate -L "$LV_SIZE" -n "$LV_NAME" "$VG_NAME"

# 5. Format and Mount
echo
echo "STEP 5: Formatting and mounting Logical Volume..."
sudo mkfs.ext4 "/dev/${VG_NAME}/${LV_NAME}"
sudo mkdir -p "$MOUNT_DIR"
sudo mount "/dev/${VG_NAME}/${LV_NAME}" "$MOUNT_DIR"
echo
echo "Mounted at: $MOUNT_DIR"
df -h "$MOUNT_DIR"

# 6. Display LVM Metadata
echo
echo "STEP 6: Displaying LVM details..."
sudo pvdisplay
sudo vgdisplay
sudo lvdisplay

# 7. Extend LV and Grow Filesystem
echo
echo "STEP 7: Extending Logical Volume by $EXTEND_SIZE..."
sudo lvextend -L "$EXTEND_SIZE" "/dev/${VG_NAME}/${LV_NAME}"
sudo resize2fs "/dev/${VG_NAME}/${LV_NAME}"
echo
df -h "$MOUNT_DIR"

echo
echo "===== STORAGE VIRTUALIZATION COMPLETED SUCCESSFULLY ====="
echo "Physical Volume: $DISK"
echo "Volume Group: $VG_NAME"
echo "Logical Volume: $LV_NAME"
echo "Mount Point: $MOUNT_DIR"

#!/bin/bash
# ---------------------------------------------
# Experiment 6A & 6B: KVM Setup, VM Creation & Image Conversion
# Author: <Your Name>
# Date: $(date +"%d-%m-%Y")
# ---------------------------------------------

echo "===== EXPERIMENT 6A & 6B AUTOMATION SCRIPT ====="
echo

# 1. CHECK HARDWARE AND SYSTEM CAPABILITIES
echo "STEP 1: Checking hardware virtualization support..."
echo "---------------------------------------------------"
sleep 1

echo -n "Virtualization support (vmx/svm): "
egrep -c '(vmx|svm)' /proc/cpuinfo

echo -n "64-bit CPU support (lm flag): "
egrep -c ' lm ' /proc/cpuinfo

echo -n "Kernel architecture: "
uname -m
echo

# 2. UPDATE SYSTEM AND INSTALL REQUIRED PACKAGES
echo "STEP 2: Updating system and installing KVM packages..."
echo "---------------------------------------------------"
sleep 1

apt update -y
apt install -y qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils virt-manager qemu-system

# 3. ENABLE AND START LIBVIRT SERVICE
echo
echo "STEP 3: Enabling and starting libvirtd service..."
systemctl enable --now libvirtd
systemctl status libvirtd --no-pager

# 4. ADD USER TO LIBVIRT & KVM GROUPS
echo
echo "STEP 4: Adding current user to libvirt and kvm groups..."
usermod -aG libvirt,kvm $SUDO_USER
echo "User added successfully! (You may need to log out and log back in)"
echo

# 5. VERIFY INSTALLATION
echo "STEP 5: Verifying KVM installation..."
echo "--------------------------------------"
virsh --version
qemu-system-x86_64 --version
virsh list --all || true
virsh nodeinfo
echo
lsmod | grep kvm

# 6. CREATE VM DISK IMAGE (OPTIONAL)
echo
echo "STEP 6: Creating a new qcow2 disk image (optional)..."
read -p "Do you want to create a new image? (y/n): " CREATE_IMG
if [[ $CREATE_IMG == "y" || $CREATE_IMG == "Y" ]]; then
    read -p "Enter image name (without extension): " IMGNAME
    read -p "Enter image size (e.g. 20G): " IMGSIZE
    qemu-img create -f qcow2 /var/lib/libvirt/images/${IMGNAME}.qcow2 $IMGSIZE
    echo "Image created at /var/lib/libvirt/images/${IMGNAME}.qcow2"
fi

# 7. IMAGE CONVERSION OPTIONS (Experiment 6B)
echo
echo "STEP 7: Image format conversion options..."
read -p "Do you want to convert an image? (y/n): " CONVERT_IMG
if [[ $CONVERT_IMG == "y" || $CONVERT_IMG == "Y" ]]; then
    read -p "Enter input image path: " SRC
    read -p "Enter output file name (without extension): " DST
    echo "Choose output format:"
    echo "1) raw (.img)"
    echo "2) vhd (.vpc)"
    echo "3) qcow2"
    read -p "Select option (1/2/3): " OPT

    case $OPT in
        1)
            qemu-img convert -O raw "$SRC" "${DST}.img" -p
            echo "Converted to RAW format: ${DST}.img"
            ;;
        2)
            qemu-img convert -O vpc "$SRC" "${DST}.vhd" -p
            echo "Converted to VHD format: ${DST}.vhd"
            ;;
        3)
            qemu-img convert -O qcow2 "$SRC" "${DST}.qcow2" -p
            echo "Converted to QCOW2 format: ${DST}.qcow2"
            ;;
        *)
            echo "Invalid option selected!"
            ;;
    esac
fi

# 8. OPTIONAL: RESIZE DISK IMAGE
echo
echo "STEP 8: Resize disk image (optional)..."
read -p "Do you want to resize an image? (y/n): " RESIZE_IMG
if [[ $RESIZE_IMG == "y" || $RESIZE_IMG == "Y" ]]; then
    read -p "Enter image file path: " RESIZE_FILE
    read -p "Enter size to add (e.g. +10G): " SIZE_ADD
    qemu-img resize "$RESIZE_FILE" $SIZE_ADD
    echo "Resized successfully!"
fi

# 9. SUMMARY
echo
echo "===== SUMMARY ====="
echo "✅ KVM installed and configured."
echo "✅ libvirtd service enabled and running."
echo "✅ User added to libvirt and kvm groups."
echo "✅ virt-manager available for GUI VM creation."
echo "✅ qemu-img conversion and resize utilities ready."
echo
echo "To create and manage VMs: run 'virt-manager' from GUI or terminal."
echo "To see your VMs: run 'virsh list --all'."
echo "Reboot or re-login if user permission issues occur."
echo
echo "===== SCRIPT COMPLETED SUCCESSFULLY ====="

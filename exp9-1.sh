#!/usr/bin/env bash
# ex9_openvswitch_temp.sh — Temporary Open vSwitch bridge setup
set -euo pipefail

# ======== CONFIGURATION (you can override via arguments) ========
IFACE="${1:-enp0s3}"         # Physical network interface
IPCIDR="${2:-10.0.2.15/24}"  # IP address and CIDR
GW="${3:-10.0.2.2}"          # Default gateway
BR="ovs-br0"                 # OVS bridge name
# ================================================================

echo "===== Open vSwitch (OVS) Bridge Setup ====="

echo "Cleaning up any existing OVS bridge..."
ovs-vsctl --if-exists del-br "$BR" || true

echo "Installing required packages..."
DEBIAN_FRONTEND=noninteractive apt-get update -y
DEBIAN_FRONTEND=noninteractive apt-get install -y openvswitch-switch net-tools iproute2

echo "Enabling and starting OVS service..."
systemctl enable --now openvswitch-switch

echo "Creating OVS bridge: $BR"
ovs-vsctl add-br "$BR"

echo "Adding interface $IFACE to OVS bridge..."
ovs-vsctl add-port "$BR" "$IFACE"

echo "Flushing existing IPs from $IFACE..."
# Flush both IPv4 and IPv6 addresses
ip -4 addr flush dev "$IFACE" 2>/dev/null || true
ip -6 addr flush dev "$IFACE" 2>/dev/null || true

echo "Assigning IP $IPCIDR to $BR..."
ip addr add "$IPCIDR" dev "$BR"

echo "Bringing interfaces up..."
ip link set "$IFACE" up
ip link set "$BR" up

echo "Setting default route via $GW..."
ip route replace default via "$GW" dev "$BR"

echo
echo "===== Final Configuration ====="
ovs-vsctl show
echo
ip -br a
echo
ip route
echo
echo "✅ OVS bridge '$BR' configured successfully!"
echo "   Interface: $IFACE"
echo "   IP: $IPCIDR"
echo "   Gateway: $GW"






# Note: Commands

# Experiment 10 — Storage virtualization with LVM

## After adding a new virtual disk in VirtualBox (e.g., 10G attached as /dev/sdb), inside the VM:
sudo -s

## Identify the new disk
fdisk -l   # find /dev/sdb (or as detected)

## Inspect current LVM (optional)
pvdisplay
vgdisplay
lvdisplay

## Create PV, VG, and LV (adjust names/sizes)
pvcreate /dev/sdb
vgcreate ubuntu-vg /dev/sdb
lvcreate -L 5G -n ubuntu-lv ubuntu-vg

## Make filesystem and mount
mkfs.ext4 /dev/ubuntu-vg/ubuntu-lv
mkdir -p /mnt/lvm-demo
mount /dev/ubuntu-vg/ubuntu-lv /mnt/lvm-demo
df -h | grep lvm-demo

## Extend LV and grow filesystem later
lvresize --size +2G ubuntu-vg/ubuntu-lv
resize2fs /dev/ubuntu-vg/ubuntu-lv
df -h | grep lvm-demo
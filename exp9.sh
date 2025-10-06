#!/usr/bin/env bash
# ex9_linux_bridge_temp.sh — Temporary Linux bridge using brctl
set -euo pipefail

IFACE="${1:-eth0}"
IPCIDR="${2:-10.0.2.15/24}"
GW="${3:-10.0.2.2}"
BR="br-cloud"

echo "Cleaning up any existing bridge..."
ip link delete "$BR" 2>/dev/null || true

DEBIAN_FRONTEND=noninteractive apt-get update -y
DEBIAN_FRONTEND=noninteractive apt-get install -y bridge-utils net-tools iproute2

echo "Creating bridge $BR and adding interface $IFACE..."
ip link add name "$BR" type bridge
ip link set "$IFACE" master "$BR"

echo "Flushing addresses from $IFACE..."
# Flush both IPv4 and IPv6 addresses separately
ip -4 addr flush dev "$IFACE" 2>/dev/null || true
ip -6 addr flush dev "$IFACE" 2>/dev/null || true

echo "Configuring bridge with IP $IPCIDR..."
ip addr add "$IPCIDR" dev "$BR"
ip link set "$IFACE" up
ip link set "$BR" up

echo "Setting up routing via $GW..."
ip route replace default via "$GW" dev "$BR"

echo "=== Final Configuration ==="
brctl show
ip -br a
ip route
echo "Linux bridge $BR configured with $IPCIDR via $GW"
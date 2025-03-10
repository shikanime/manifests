#!/bin/bash

set -euo pipefail

# Ensure system configuration is up to date
sysctl --system

# Install Longhorn dependencies
apt-get update -y
apt-get install -y \
    open-iscsi \
    nfs-common \
    cryptsetup \
    dmsetup \
    jq

# Install k3s
curl -sfL https://get.k3s.io | K3S_TOKEN="${token}" \
    sh -s - \
    --cluster-cidr "10.42.0.0/16,2001:cafe:42::/56" \
    --disable-etcd \
    --flannel-backend "host-gw" \
    --flannel-ipv6-masq \
    --node-ip "$(tailscale status -json | jq -r '.TailscaleIPs | join(",")')" \
    --protect-kernel-defaults \
    --server "${server}" \
    --service-cidr "10.43.0.0/16,2001:cafe:43::/112" \
    --tls-san "$(tailscale status -json | jq -r '.CertDomains | join(",")')"

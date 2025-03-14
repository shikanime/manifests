#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

# Ensure system configuration is up to date
systemd-tmpfiles --create
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
curl -sfL https://get.k3s.io |
  K3S_ETCD_S3_SECRET_KEY="${etcd_secret_key}" \
    sh -s - server \
    --cluster-init \
    --cluster-cidr "10.42.0.0/16,2001:cafe:42::/56" \
    --etcd-s3 \
    --etcd-s3-access-key "${etcd_access_key}" \
    --etcd-s3-bucket "${etcd_bucket}" \
    --etcd-s3-endpoint "${etcd_endpoint}" \
    --etcd-s3-region "${etcd_region}" \
    --flannel-backend "host-gw" \
    --flannel-ipv6-masq \
    --node-ip "$(tailscale status -json | jq -r '.TailscaleIPs | join(",")')" \
    --protect-kernel-defaults \
    --service-cidr "10.43.0.0/16,2001:cafe:43::/112" \
    --tls-san "$(tailscale status -json | jq -r '.CertDomains | join(",")')"

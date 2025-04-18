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

# Install RKE2
curl -sfL https://get.rke2.io | INSTALL_RKE2_TYPE=agent sh -s -

# Enable RKE2 service to start on boot
systemctl enable rke2-agent.service

# Create a directory for RKE2 configuration
mkdir -p /etc/rancher/rke2

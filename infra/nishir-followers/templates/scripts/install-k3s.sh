#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

# Ensure system configuration is up to date
sysctl --system

# Install Longhorn dependencies
apt-get update -y
apt-get install -y \
  open-iscsi \
  nfs-common \
  cryptsetup \
  dmsetup

# Install k3s
curl -sfL https://get.k3s.io |
  K3S_TOKEN="${token}" K3S_URL="${server}" \
    sh -s -

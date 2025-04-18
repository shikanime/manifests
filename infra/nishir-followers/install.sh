#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

# Find the nishir server name from tailscale
SERVER=$(tailscale status -json | jq -r '.Peer[] | select(.HostName == "nishir") | .DNSName' | sed 's/\.$//')

# SSH into nishir and retrieve the server token
TOKEN=$(ssh "root@${SERVER}" "cat /var/lib/rancher/rke2/server/node-token")

# Create JSON using jq
jq -n \
  --arg token "${TOKEN}" \
  --arg server "${SERVER}" \
  '{rke2: {token: $token, server: $server}}' >"$(dirname "$0")/terraform.tfvars.json"

# Set secure permissions for the tfvars file
chmod 600 "$(dirname "$0")/terraform.tfvars.json"

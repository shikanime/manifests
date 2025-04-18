#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

# SSH into nishir and retrieve the server token
NODE_TOKEN=$(ssh "root@${SERVER}" "cat /var/lib/rancher/rke2/server/node-token")

# Find the nishir server name from tailscale
SERVER=$(tailscale status -json | jq -r '.Peer[] | select(.HostName == "nishir") | .DNSName' | sed 's/\.$//')

# Create JSON using jq
jq -n \
  --arg node_token "${NODE_TOKEN}" \
  --arg server "${SERVER}" \
  '{rke2: {node_token: $node_token, server: $server}}' >"$(dirname "$0")/terraform.tfvars.json"

# Set secure permissions for the tfvars file
chmod 600 "$(dirname "$0")/terraform.tfvars.json"

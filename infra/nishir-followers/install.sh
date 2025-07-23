#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

# Find the nishir server name from tailscale
SERVER=$(tailscale status -json | jq -r '.Peer[] | select(.HostName == "nishir") | .DNSName' | sed 's/\.$//')

# Get node IPs for minish and fushi from tailscale
MINISH_IP=$(tailscale status -json | jq -r '[.Peer[] | select(.HostName == "minish") | .TailscaleIPs[0]]')
FUSHI_IP=$(tailscale status -json | jq -r '[.Peer[] | select(.HostName == "fushi") | .TailscaleIPs[0]]')

# SSH into nishir and retrieve the server token
NODE_TOKEN=$(ssh "root@${SERVER}" "cat /var/lib/rancher/rke2/server/token")

# Create JSON using jq
jq -n \
  --arg node_token "${NODE_TOKEN}" \
  --arg server "${SERVER}" \
  --argjson minish_ip "${MINISH_IP}" \
  --argjson fushi_ip "${FUSHI_IP}" \
  '{
    nodes: {
      minish: { node_ip: $minish_ip },
      fushi: { node_ip: $fushi_ip }
    },
    rke2: {
      node_token: $node_token,
      server: $server,
    }
  }' >"$(dirname "$0")/terraform.tfvars.json"

# Set secure permissions for the tfvars file
chmod 600 "$(dirname "$0")/terraform.tfvars.json"

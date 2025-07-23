#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

# Find the nishir server name from tailscale
NODE_IP=$(tailscale status -json | jq -r '[.Peer[] | select(.HostName == "nishir") | .TailscaleIPs[0]]')
# Get TLS SAN domains from Tailscale
TLS_SAN=$(tailscale status -json | jq -r '.Peer[] | select(.HostName == "nishir") | .DNSName | rtrimstr(".")')

# Fetch all outputs at once and combine with RKE2 configuration
tofu -chdir="$(dirname "$0")/../nishir-services" output -json |
  jq --argjson node_ip "${NODE_IP}" \
    --arg tls_san "${TLS_SAN}" \
    'with_entries(
    select(.key | IN(
      "etcd_snapshot",
      "tailscale_operator"
    )) |
    .value = .value.value
  ) + {rke2: {tls_san: $tls_san, node_ip: $node_ip}}' >"$(dirname "$0")/terraform.tfvars.json"

# Set secure permissions for the tfvars file
chmod 600 "$(dirname "$0")/terraform.tfvars.json"

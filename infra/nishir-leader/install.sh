#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

# Find the nishir server name from tailscale
NODE_IP=$(tailscale status -json | jq -r '.Peer[] | select(.HostName == "nishir") | .TailscaleIPs')
# Get TLS SAN domains from Tailscale
TLS_SANS=$(tailscale status -json | jq -r '.Peer[] | select(.HostName == "nishir") | [.HostName, .HostName + ".local", .DNSName | rtrimstr(".")]')

# Fetch all outputs at once and combine with RKE2 configuration
tofu -chdir="$(dirname "$0")/../nishir-services" output -json |
  jq \
    --argjson node_ip "${NODE_IP}" \
    --argjson tls_sans "${TLS_SANS}" \
    'with_entries(
    select(.key | IN(
      "etcd_snapshot",
      "tailscale_operator"
    )) |
    .value = .value.value
  ) + {rke2: {tls_sans: $tls_sans, node_ip: $node_ip}}' >"$(dirname "$0")/terraform.tfvars.json"

# Set secure permissions for the tfvars file
chmod 600 "$(dirname "$0")/terraform.tfvars.json"

#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

# Find the nishir server name from tailscale
SERVER=$(tailscale status -json | jq -r '.Peer[] | select(.HostName == "nishir") | .HostName')

# Get TLS SAN domains from Tailscale
TLS_SANS=$(tailscale status -json | jq -r '.Peer[] | select(.HostName == "nishir") | [.HostName, .HostName + ".local", .DNSName | rtrimstr(".")]')

# Get Tailscale IPs
TAILSCALE_IPS=$(tailscale status -json | jq -r '.Peer[] | select(.HostName == "nishir") | .TailscaleIPs')

# Retrieve both IPv4 and IPv6 addresses from eth0 and wlan0 interfaces in a single SSH command
INTERFACE_IPS=$(ssh "root@${SERVER}" "ip -j addr show | jq '[.[] | select(.ifname == \"eth0\" or .ifname == \"wlan0\") | .addr_info[] | select(.family == \"inet\" or .family == \"inet6\") | .local]'")

# Combine Tailscale and interface IPs
NODE_IP=$(jq -n --argjson tailscale "${TAILSCALE_IPS}" --argjson interface_ips "${INTERFACE_IPS}" '$interface_ips + $tailscale')

# Fetch all outputs at once and combine with RKE2 configuration
tofu -chdir="$(dirname "$0")/../nishir-services" output -json |
  jq \
    --argjson node_ip "${NODE_IP}" \
    --argjson tls_san "${TLS_SANS}" \
    'with_entries(
    select(.key | IN(
      "etcd_snapshot",
      "tailscale_operator"
    )) |
    .value = .value.value
  ) + {rke2: {tls_san: $tls_san, node_ip: $node_ip}}' >"$(dirname "$0")/terraform.tfvars.json"

# Set secure permissions for the tfvars file
chmod 600 "$(dirname "$0")/terraform.tfvars.json"

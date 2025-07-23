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

# SSH into nishir and retrieve IPv4 addresses from eth0 and wlan0 interfaces only
ETH_IPV4=$(ssh "root@${SERVER}" "ip -j addr show | jq -r '[.[] | select(.ifname == \"eth0\" or .ifname == \"wlan0\") | .addr_info[] | select(.family == \"inet\") | .local]'")

# SSH into nishir and retrieve IPv6 addresses from eth0 and wlan0 interfaces only
ETH_IPV6=$(ssh "root@${SERVER}" "ip -j addr show | jq -r '[.[] | select(.ifname == \"eth0\" or .ifname == \"wlan0\") | .addr_info[] | select(.family == \"inet6\") | .local]'")

# Combine Tailscale and Ethernet IPs (both IPv4 and IPv6)
NODE_IP=$(jq -n --argjson tailscale "${TAILSCALE_IPS}" --argjson ipv4 "${ETH_IPV4}" --argjson ipv6 "${ETH_IPV6}" '$ipv4 + $ipv6 + $tailscale')

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

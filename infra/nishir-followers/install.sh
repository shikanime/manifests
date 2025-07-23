#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

# Find the nishir server name from tailscale
SERVER=$(tailscale status -json | jq -r '.Peer[] | select(.HostName == "nishir") | .HostName')

# Get Tailscale IPs for minish and fushi
MINISH_TAILSCALE_IPS=$(tailscale status -json | jq -r '.Peer[] | select(.HostName == "minish") | .TailscaleIPs')
FUSHI_TAILSCALE_IPS=$(tailscale status -json | jq -r '.Peer[] | select(.HostName == "fushi") | .TailscaleIPs')

# Retrieve both IPv4 and IPv6 addresses (excluding link-local) from eth0 and wlan0 interfaces for minish in a single SSH command
MINISH_INTERFACE_IPS=$(ssh "root@minish" "ip -j addr show | jq '[.[] | select(.ifname == \"eth0\" or .ifname == \"wlan0\") | .addr_info[] | select(.family == \"inet\" or (.family == \"inet6\" and (.local | startswith(\"fe80:\") | not))) | .local]'")

# Retrieve both IPv4 and IPv6 addresses (excluding link-local) from eth0 and wlan0 interfaces for fushi in a single SSH command
FUSHI_INTERFACE_IPS=$(ssh "root@fushi" "ip -j addr show | jq '[.[] | select(.ifname == \"eth0\" or .ifname == \"wlan0\") | .addr_info[] | select(.family == \"inet\" or (.family == \"inet6\" and (.local | startswith(\"fe80:\") | not))) | .local]'")

# Combine Tailscale and interface IPs for each node
MINISH_IP=$(jq -n --argjson tailscale "${MINISH_TAILSCALE_IPS}" --argjson interface_ips "${MINISH_INTERFACE_IPS}" '$interface_ips + $tailscale')
FUSHI_IP=$(jq -n --argjson tailscale "${FUSHI_TAILSCALE_IPS}" --argjson interface_ips "${FUSHI_INTERFACE_IPS}" '$interface_ips + $tailscale')

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

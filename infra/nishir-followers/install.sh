#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

# Find the nishir server name from tailscale
server=$(tailscale status -json | jq -r '.Peer[] | select(.HostName == "nishir") | .DNSName' | sed 's/\.$//')

# SSH into nishir and retrieve the server token
token=$(ssh "root@${server}" "cat /var/lib/rancher/k3s/server/token")

# Create JSON using jq
jq -n \
  --arg token "${token}" \
  --arg server "${server}" \
  '{k3s: {token: $token, server: $server}}' >"$(dirname "$0")/terraform.tfvars.json"

# Set secure permissions for the tfvars file
chmod 600 "$(dirname "$0")/terraform.tfvars.json"

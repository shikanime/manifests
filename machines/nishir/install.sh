#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

# Get the directory where this script is located
CLUSTER_YAML="$(dirname "$0")/cluster.yaml"

# Get Tailscale IPs for all three nodes
echo "Fetching Tailscale IPs..."
NISHIR_IP=$(tailscale status -json | jq -r '.Peer[] | select(.HostName == "nishir") | .TailscaleIPs[0]')
FUSHI_IP=$(tailscale status -json | jq -r '.Peer[] | select(.HostName == "fushi") | .TailscaleIPs[0]')
MINISH_IP=$(tailscale status -json | jq -r '.Peer[] | select(.HostName == "minish") | .TailscaleIPs[0]')

# Validate that we got valid IPs
if [[ -z $NISHIR_IP || $NISHIR_IP == "null" ]]; then
  echo "Error: Could not find Tailscale IP for nishir"
  exit 1
fi

if [[ -z $FUSHI_IP || $FUSHI_IP == "null" ]]; then
  echo "Error: Could not find Tailscale IP for fushi"
  exit 1
fi

if [[ -z $MINISH_IP || $MINISH_IP == "null" ]]; then
  echo "Error: Could not find Tailscale IP for minish"
  exit 1
fi

# Update the cluster.yaml file using yq
yq eval ".spec.hosts[0].ssh.address = \"$NISHIR_IP\"" -i "$CLUSTER_YAML"
yq eval ".spec.hosts[1].ssh.address = \"$FUSHI_IP\"" -i "$CLUSTER_YAML"
yq eval ".spec.hosts[2].ssh.address = \"$MINISH_IP\"" -i "$CLUSTER_YAML"

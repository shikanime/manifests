#!/usr/bin/env nix
#! nix develop --impure --command bash

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

# Update the cluster.yaml file using yq
yq eval ".spec.hosts[0].ssh.address = \"$NISHIR_IP\"" -i "$CLUSTER_YAML"
yq eval ".spec.hosts[1].ssh.address = \"$FUSHI_IP\"" -i "$CLUSTER_YAML"
yq eval ".spec.hosts[2].ssh.address = \"$MINISH_IP\"" -i "$CLUSTER_YAML"

# Get the longhorn_backupstore output from nishir-services
BACKUP_CONFIG=$(tofu -chdir="$(dirname "$0")/../../infra/nishir-services" output -json longhorn_backupstore)

# Extract bucket and region
BUCKET=$(echo "$BACKUP_CONFIG" | jq -r '.bucket')
REGION=$(echo "$BACKUP_CONFIG" | jq -r '.region')

# Update the cluster.yaml file
sed -i \
  -e "s|backupTarget:.*$|backupTarget: s3://${BUCKET}@${REGION}/|g" \
  "$(dirname "$0")/cluster.yaml"

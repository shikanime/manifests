#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

# Get Tailscale status for FTP device in JSON format
FTP_IP=$(tailscale status -json | jq -r '({("\(.Self.PublicKey)"): .Self} + .Peer)[] | select(.HostName=="ftp") | .TailscaleIPs[0]')

# Update the StatefulSet YAML with the new IP
yq -i ".spec.template.spec.containers[0].env[0].value = \"${FTP_IP}\"" \
  "$(dirname "$0")/patch-deploy.yaml"
